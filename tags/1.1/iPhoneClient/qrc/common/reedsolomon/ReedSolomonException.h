#ifndef __REED_SOLOMON_EXCEPTION_H__
#define __REED_SOLOMON_EXCEPTION_H__

/*
 *  ReedSolomonException.h
 *  zxing
 *
 *  Created by Christian Brunschen on 06/05/2008.
 *  Copyright 2008 Google UK. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "../../Exception.h"

namespace reedsolomon {
  class ReedSolomonException : public Exception {
  public:
    ReedSolomonException(const char *msg) throw() : Exception(msg) { }
    ~ReedSolomonException() throw() { } 
  };
}

#endif // __REED_SOLOMON_EXCEPTION_H__