
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

namespace DB
{

class FunctionFactory;

void registerFunctionIsNull(FunctionFactory & factory);
void registerFunctionIsNotNull(FunctionFactory & factory);
void registerFunctionCoalesce(FunctionFactory & factory);
void registerFunctionIfNull(FunctionFactory & factory);
void registerFunctionNullIf(FunctionFactory & factory);
void registerFunctionAssumeNotNull(FunctionFactory & factory);
void registerFunctionToNullable(FunctionFactory & factory);
void registerFunctionIsZeroOrNull(FunctionFactory & factory);
void registerFunctionUnifyNull(FunctionFactory & factory);


void registerFunctionsNull(FunctionFactory & factory)
{
    registerFunctionIsNull(factory);
    registerFunctionIsNotNull(factory);
    registerFunctionCoalesce(factory);
    registerFunctionIfNull(factory);
    registerFunctionNullIf(factory);
    registerFunctionAssumeNotNull(factory);
    registerFunctionToNullable(factory);
    registerFunctionIsZeroOrNull(factory);
    registerFunctionUnifyNull(factory);
}

}
