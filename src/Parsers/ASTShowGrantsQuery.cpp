#include <Parsers/ASTShowGrantsQuery.h>
#include <Parsers/ASTRolesOrUsersSet.h>
#include <Parsers/formatTenantDatabaseName.h>
#include <Common/quoteString.h>
#include <IO/Operators.h>
#include <Interpreters/Context.h>


namespace DB
{
String ASTShowGrantsQuery::getID(char) const
{
    return "ShowGrantsQuery";
}


ASTPtr ASTShowGrantsQuery::clone() const
{
    return std::make_shared<ASTShowGrantsQuery>(*this);
}


void ASTShowGrantsQuery::formatQueryImpl(const FormatSettings & settings, FormatState &, FormatStateStacked) const
{
    settings.ostr << (settings.hilite ? hilite_keyword : "") << "SHOW GRANTS"
                  << (settings.hilite ? hilite_none : "");

    if (for_roles->current_user && !for_roles->all && for_roles->names.empty() && for_roles->except_names.empty()
        && !for_roles->except_current_user)
    {
    }
    else
    {
        settings.ostr << (settings.hilite ? hilite_keyword : "") << " FOR "
                      << (settings.hilite ? hilite_none : "");
        for_roles->format(settings);
    }
}

void ASTShowGrantsQuery::rewriteNamesWithTenant(const Context *)
{
    if (!tenant_rewritten)
    {
        if (for_roles)
        {
            for (auto & name : for_roles->names)
                name = formatTenantEntityName(name);
            for (auto & name : for_roles->except_names)
                name = formatTenantEntityName(name);
        }

        tenant_rewritten = true;
    }  
}
}
