
/*
 * Copyright 2016-2023 ClickHouse, Inc.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/*
 * This file may have been modified by Bytedance Ltd. and/or its affiliates (“ Bytedance's Modifications”).
 * All Bytedance's Modifications are Copyright (2023) Bytedance Ltd. and/or its affiliates.
 */

#pragma once

#include <Parsers/IParser.h>
#include <Parsers/IParserBase.h>


namespace DB
{

/// Parse query or set 'out_error_message'.
ASTPtr tryParseQuery(
    IParser & parser,
    const char * & _out_query_end, // query start as input parameter, query end as output
    const char * end,
    std::string & out_error_message,
    bool hilite,
    const std::string & description,
    bool allow_multi_statements,    /// If false, check for non-space characters after semicolon and set error message if any.
    size_t max_query_size,          /// If (end - pos) > max_query_size and query is longer than max_query_size then throws "Max query size exceeded".
                                    /// Disabled if zero. Is used in order to check query size if buffer can contains data for INSERT query.
    size_t max_parser_depth);


/// Parse query or throw an exception with error message.
ASTPtr parseQueryAndMovePosition(
    IParser & parser,
    const char * & pos,                /// Moved to end of parsed fragment.
    const char * end,
    const std::string & description,
    bool allow_multi_statements,
    size_t max_query_size,
    size_t max_parser_depth);

ASTPtr parseQuery(
    IParser & parser,
    const char * begin,
    const char * end,
    const std::string & description,
    size_t max_query_size,
    size_t max_parser_depth);

ASTPtr parseQuery(
    IParser & parser,
    const std::string & query,
    const std::string & query_description,
    size_t max_query_size,
    size_t max_parser_depth);

ASTPtr parseQuery(
    IParser & parser,
    const std::string & query,
    size_t max_query_size,
    size_t max_parser_depth);


/** Split queries separated by ; on to list of single queries
  * Returns pointer to the end of last successfully parsed query (first), and true if all queries are successfully parsed (second)
  * NOTE: INSERT's data should be placed in single line.
  */
std::pair<const char *, bool> splitMultipartQuery(
    const std::string & queries,
    std::vector<std::string> & queries_list,
    size_t max_query_size,
    size_t max_parser_depth,
    ParserSettingsImpl dialect_type);

}
