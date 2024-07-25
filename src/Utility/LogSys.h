/*
 * This file is part of QBDI.
 *
 * Copyright 2017 - 2024 Quarkslab
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef LOGSYS_H
#define LOGSYS_H

#include <memory>
#include <string>

#include "QBDI/Config.h"
#include "QBDI/Logs.h"
#include "QBDI/Options.h"
#include "QBDI/State.h"
#include "spdlog/spdlog.h"

namespace llvm {
class MCInst;
}

namespace QBDI {
class LLVMCPU;
class InstMetadata;
class Patch;

#define QBDI_INFO(...) SPDLOG_INFO(__VA_ARGS__)
#define QBDI_WARN(...) SPDLOG_WARN(__VA_ARGS__)
#define QBDI_ERROR(...) SPDLOG_ERROR(__VA_ARGS__)
#define QBDI_CRITICAL(...) SPDLOG_CRITICAL(__VA_ARGS__)

#if defined(QBDI_LOG_DEBUG)
#define QBDI_DEBUG_BLOCK(block) block
#define QBDI_DEBUG(...) SPDLOG_DEBUG(__VA_ARGS__)
#else
#define QBDI_DEBUG_BLOCK(block) \
  { (void)0; }
#define QBDI_DEBUG(...) (void)0
#endif

#define QBDI_REQUIRE(req)                      \
  if (!(req)) {                                \
    QBDI_ERROR("Assertion Failed : {}", #req); \
  }
#define QBDI_REQUIRE_ACTION(req, ac)           \
  if (!(req)) {                                \
    QBDI_ERROR("Assertion Failed : {}", #req); \
    ac;                                        \
  }
#define QBDI_REQUIRE_ABORT(req, ...) \
  if (!(req)) {                      \
    QBDI_CRITICAL(__VA_ARGS__);      \
    spdlog::shutdown();              \
    abort();                         \
  }
#define QBDI_ABORT(...)         \
  do {                          \
    QBDI_CRITICAL(__VA_ARGS__); \
    spdlog::shutdown();         \
    abort();                    \
  } while (0);

// formatter of internal enum
inline uint32_t format_as(Options opt) { return opt; }
inline uint32_t format_as(CPUMode mode) { return mode; }
std::string format_as(const QBDI::Patch &patch);

} // namespace QBDI

#endif
