import pytest
import time
import psycopg2
import os.path as p

from helpers.cluster import ClickHouseCluster
from helpers.test_tools import assert_eq_with_retry
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from helpers.test_tools import TSV

cluster = ClickHouseCluster(__file__)
instance = cluster.add_instance('instance', main_configs=['configs/log_conf.xml'], with_postgres=True, stay_alive=True)

postgres_table_template = """
    CREATE TABLE IF NOT EXISTS {} (
    key Integer NOT NULL, value Integer, PRIMARY KEY(key))
    """

def get_postgres_conn(ip, port, database=False, auto_commit=True, database_name='postgres_database'):
    if database == True:
        conn_string = "host={} port={} dbname='{}' user='postgres' password='mysecretpassword'".format(ip, port, database_name)
    else:
        conn_string = "host={} port={} user='postgres' password='mysecretpassword'".format(ip, port)

    conn = psycopg2.connect(conn_string)
    if auto_commit:
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        conn.autocommit = True
    return conn


def create_postgres_db(cursor, name):
    cursor.execute("CREATE DATABASE {}".format(name))

def create_clickhouse_postgres_db(ip, port, name='postgres_database'):
    instance.query('''
            CREATE DATABASE {}
            ENGINE = PostgreSQL('{}:{}', '{}', 'postgres', 'mysecretpassword')'''.format(name, ip, port, name))

def create_materialized_table(ip, port):
    instance.query('''
        CREATE TABLE test.postgresql_replica (key UInt64, value UInt64)
            ENGINE = MaterializePostgreSQL(
            '{}:{}', 'postgres_database', 'postgresql_replica', 'postgres', 'mysecretpassword')
            PRIMARY KEY key; '''.format(ip, port))

def create_postgres_table(cursor, table_name, replica_identity_full=False):
    cursor.execute("DROP TABLE IF EXISTS {}".format(table_name))
    cursor.execute(postgres_table_template.format(table_name))
    if replica_identity_full:
        cursor.execute('ALTER TABLE {} REPLICA IDENTITY FULL;'.format(table_name))


def postgresql_replica_check_result(result, check=False, ref_file='test_postgresql_replica.reference'):
    fpath = p.join(p.dirname(__file__), ref_file)
    with open(fpath) as reference:
        if check:
            assert TSV(result) == TSV(reference)
        else:
            return TSV(result) == TSV(reference)


@pytest.fixture(scope="module")
def started_cluster():
    try:
        cluster.start()
        conn = get_postgres_conn(ip=cluster.postgres_ip,
                                 port=cluster.postgres_port)
        cursor = conn.cursor()
        create_postgres_db(cursor, 'postgres_database')
        create_clickhouse_postgres_db(ip=cluster.postgres_ip,
                                      port=cluster.postgres_port)

        instance.query('CREATE DATABASE test')
        yield cluster

    finally:
        cluster.shutdown()

@pytest.fixture(autouse=True)
def postgresql_setup_teardown():
    yield  # run test
    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')


@pytest.mark.timeout(320)
def test_initial_load_from_snapshot(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    while postgresql_replica_check_result(result) == False:
        time.sleep(0.2)
        result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')

    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_no_connection_at_startup(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)
    time.sleep(3)

    instance.query('DETACH TABLE test.postgresql_replica')
    started_cluster.pause_container('postgres1')

    instance.query('ATTACH TABLE test.postgresql_replica')
    time.sleep(3)
    started_cluster.unpause_container('postgres1')

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while int(result) == 0:
        time.sleep(0.5);
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_detach_attach_is_ok(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) == 0):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    postgresql_replica_check_result(result, True)

    instance.query('DETACH TABLE test.postgresql_replica')
    instance.query('ATTACH TABLE test.postgresql_replica')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    while postgresql_replica_check_result(result) == False:
        time.sleep(0.5)
        result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')

    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_replicating_insert_queries(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(10)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 10):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT 10 + number, 10 + number from numbers(10)")
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT 20 + number, 20 + number from numbers(10)")

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 30):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT 30 + number, 30 + number from numbers(10)")
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT 40 + number, 40 + number from numbers(10)")

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 50):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_replicating_delete_queries(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    while postgresql_replica_check_result(result) == False:
        time.sleep(0.2)
        result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT 50 + number, 50 + number from numbers(50)")

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while int(result) != 100:
        time.sleep(0.5)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    cursor.execute('DELETE FROM postgresql_replica WHERE key > 49;')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    while postgresql_replica_check_result(result) == False:
        time.sleep(0.5)
        result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')

    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_replicating_update_queries(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number + 10 from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 50):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    cursor.execute('UPDATE postgresql_replica SET value = value - 10;')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    while postgresql_replica_check_result(result) == False:
        time.sleep(0.5)
        result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')

    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_resume_from_written_version(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number + 10 from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 50):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT 50 + number, 50 + number from numbers(50)")

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 100):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    instance.query('DETACH TABLE test.postgresql_replica')

    cursor.execute('DELETE FROM postgresql_replica WHERE key > 49;')
    cursor.execute('UPDATE postgresql_replica SET value = value - 10;')

    instance.query('ATTACH TABLE test.postgresql_replica')

    result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')
    while postgresql_replica_check_result(result) == False:
        time.sleep(0.5)
        result = instance.query('SELECT * FROM test.postgresql_replica ORDER BY key;')

    cursor.execute('DROP TABLE postgresql_replica;')
    postgresql_replica_check_result(result, True)


@pytest.mark.timeout(320)
def test_many_replication_messages(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(100000)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 100000):
        time.sleep(0.2)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')
    print("SYNC OK")

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(100000, 100000)")

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while (int(result) != 200000):
        time.sleep(1)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')
    print("INSERT OK")

    result = instance.query('SELECT key FROM test.postgresql_replica ORDER BY key;')
    expected = instance.query("SELECT number from numbers(200000)")
    assert(result == expected)

    cursor.execute('UPDATE postgresql_replica SET value = key + 1 WHERE key < 100000;')

    result = instance.query('SELECT key FROM test.postgresql_replica WHERE value = key + 1 ORDER BY key;')
    expected = instance.query("SELECT number from numbers(100000)")

    while (result != expected):
        time.sleep(1)
        result = instance.query('SELECT key FROM test.postgresql_replica WHERE value = key + 1 ORDER BY key;')
    print("UPDATE OK")

    cursor.execute('DELETE FROM postgresql_replica WHERE key % 2 = 1;')
    cursor.execute('DELETE FROM postgresql_replica WHERE key != value;')

    result = instance.query('SELECT count() FROM (SELECT * FROM test.postgresql_replica);')
    while (int(result) != 50000):
        time.sleep(1)
        result = instance.query('SELECT count() FROM (SELECT * FROM test.postgresql_replica);')
    print("DELETE OK")

    cursor.execute('DROP TABLE postgresql_replica;')


@pytest.mark.timeout(320)
def test_connection_loss(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    i = 50
    while i < 100000:
        instance.query("INSERT INTO postgres_database.postgresql_replica SELECT {} + number, number from numbers(10000)".format(i))
        i += 10000

    started_cluster.pause_container('postgres1')

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    print(int(result))
    time.sleep(6)

    started_cluster.unpause_container('postgres1')

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while int(result) < 100050:
        time.sleep(1)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    cursor.execute('DROP TABLE postgresql_replica;')
    assert(int(result) == 100050)


@pytest.mark.timeout(320)
def test_clickhouse_restart(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');
    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(50)")

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    i = 50
    while i < 100000:
        instance.query("INSERT INTO postgres_database.postgresql_replica SELECT {} + number, number from numbers(10000)".format(i))
        i += 10000

    instance.restart_clickhouse()

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while int(result) < 100050:
        time.sleep(1)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    cursor.execute('DROP TABLE postgresql_replica;')
    print(result)
    assert(int(result) == 100050)


def test_rename_table(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(25)")

    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while int(result) != 25:
        time.sleep(0.5)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    instance.query('RENAME TABLE test.postgresql_replica TO test.postgresql_replica_renamed')
    assert(int(instance.query('SELECT count() FROM test.postgresql_replica_renamed;')) == 25)

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(25, 25)")

    result = instance.query('SELECT count() FROM test.postgresql_replica_renamed;')
    while int(result) != 50:
        time.sleep(0.5)
        result = instance.query('SELECT count() FROM test.postgresql_replica_renamed;')

    result = instance.query('SELECT * FROM test.postgresql_replica_renamed ORDER BY key;')
    postgresql_replica_check_result(result, True)
    cursor.execute('DROP TABLE postgresql_replica;')
    instance.query('DROP TABLE IF EXISTS test.postgresql_replica_renamed')


def test_virtual_columns(started_cluster):
    conn = get_postgres_conn(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port,
                             database=True)
    cursor = conn.cursor()
    create_postgres_table(cursor, 'postgresql_replica');

    instance.query('DROP TABLE IF EXISTS test.postgresql_replica')
    create_materialized_table(ip=started_cluster.postgres_ip,
                             port=started_cluster.postgres_port)

    instance.query("INSERT INTO postgres_database.postgresql_replica SELECT number, number from numbers(10)")
    result = instance.query('SELECT count() FROM test.postgresql_replica;')
    while int(result) != 10:
        time.sleep(0.5)
        result = instance.query('SELECT count() FROM test.postgresql_replica;')

    # just check that it works, no check with `expected` becuase _version is taken as LSN, which will be different each time.
    result = instance.query('SELECT key, value, _sign, _version FROM test.postgresql_replica;')
    print(result)
    cursor.execute('DROP TABLE postgresql_replica;')


if __name__ == '__main__':
    cluster.start()
    input("Cluster created, press any key to destroy...")
    cluster.shutdown()
