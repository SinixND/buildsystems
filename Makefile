#######################################
### Config
#######################################
BIN 			:= main
LIBRARIES 		:= raylib

CC 				:= clang
CXX 			:= clang++
EMCXX			:= em++
WINCXX			:= x86_64-w64-mingw32-g++

MAKEFLAGS 		:= --no-print-directory
C_FLAGS 		:= -MMD -MP
CXX_FLAGS 		:= -std=c++20 $(C_FLAGS)
# -MMD 				provides dependency information (header files) for make in .d files 
# -pg 				ADD FOR gprof analysis TO BOTH COMPILE AND LINK COMMAND!!
# -MJ 				CLANG ONLY: compile-database
# -MP 				Multi-threaded compilation
# -Wfatal-errors 	Stop at first error
LD_FLAGS 		:= -lpthread #-fsanitize=address

USR_DIR 		:= /usr
BIN_DIR 		:= bin
OBJ_DIR 		:= build
SRC_DIR 		:= src
LIB_DIR 		:= lib
INC_DIR 		:= include

BIN_EXT 		:= 
SRC_EXT 		:= .cpp .c


#######################################
### Core
#######################################
BUILD 			:= debug
# Options: unix web windows
PLATFORM 		:= unix
FATAL 			:= false


#######################################
### Externals
#######################################
### RAYLIB
ASSETS_DIR 				:= assets
RAYLIB_SRC_DIR 			:= $(USR_DIR)/local/lib/raylib/src
INC_DIRS_SYS 			+= $(RAYLIB_SRC_DIR)

ifeq ($(PLATFORM),windows)
LIB_DIRS 			+= $(RAYLIB_SRC_DIR)
else
ifeq ($(PLATFORM),web)
ifeq ($(BUILD),debug)
LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/web/debug
else
LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/web/release
endif
else
ifeq ($(BUILD),debug)
LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/desktop/debug
else
LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/desktop/release
endif
endif
endif

ifeq ($(PLATFORM),web)
# LD_FLAGS 			+= --preload-file $(ASSETS_DIR)/ -sUSE_GLFW=3
ifeq ($(BUILD),debug)
LD_FLAGS 			+= --shell-file $(RAYLIB_SRC_DIR)/shell.html
else
LD_FLAGS 			+= --shell-file $(RAYLIB_SRC_DIR)/minshell.html
endif
endif


#######################################
### Conditionals
#######################################
### DEBUG (BUILD)
ifeq ($(BUILD),debug)

CXX_FLAGS 		+= -g -ggdb -O0 -Wall -Wextra -Wshadow -Werror -Wpedantic -pedantic-errors -DDEBUG

endif

### RELEASE (BUILD)
ifeq ($(BUILD),release)

CXX_FLAGS 		+= -O2 -DNDEBUG

endif

### FATAL
ifeq ($(FATAL),true)

CXX_FLAGS 		+= -Wfatal-errors

endif

### TERMUX (HOST_OS)
ifdef TERMUX_VERSION

CXX_FLAGS 		+= -DTERMUX
USR_DIR 		:= $(PREFIX)
ifeq ($(PLATFORM),unix)
LIBRARIES 		+= log
endif

endif

### WEB/EMSCRIPTEN (TARGET PLATFORM)
ifeq ($(PLATFORM),web)

CXX 			:= em++
EMCXX_FLAGS		:= -Os -Wall -DEMSCRIPTEN -DPLATFORM_WEB $(CXX_FLAGS)


BIN_EXT			:= .html
USR_DIR			:= 

endif

### WINDOWS (TARGET PLATFORM)
ifeq ($(PLATFORM),windows)

CXX 			:= /bin/x86_64-w64-mingw32-g++

BIN_EXT			:= .exe

USR_DIR			:= $(USR_DIR)/x86_64-w64-mingw32

LD_FLAGS 		+= -static -static-libgcc -static-libstdc++

endif

#######################################
### Automatic variables
#######################################
SRCS 			:= $(foreach e,\
					$(shell find $(SRC_DIR) -type f),\
					$(filter $(addprefix %,$(SRC_EXT)),\
						$e))
OBJS 			:= $(SRCS:%=$(OBJ_DIR)/$(BUILD)/$(PLATFORM)/%.o)
DEPS 			:= $(OBJS:.o=.d)

USR_DIRS 		:= $(USR_DIR) $(patsubst %,%/local,$(USR_DIR))
LIB_DIRS 		+= $(patsubst %,%/lib,$(USR_DIRS))
LIB_DIRS 		+= $(shell find $(LIB_DIR) -type d)
INC_DIRS 		:= $(shell find $(SRC_DIR) $(INC_DIR) -type d)
# INC_DIRS_SYS	+= $(LIB_DIRS)

INC_FLAGS 		:= $(addprefix -I,$(INC_DIRS))
INC_FLAGS 		+= $(addprefix -isystem,$(INC_DIRS_SYS))
LIB_FLAGS 		:= $(addprefix -L,$(LIB_DIRS))
LD_FLAGS 		+= $(addprefix -l,$(LIBRARIES))


#######################################
### Targets
#######################################
.PHONY: all
all: debug release

.PHONY: analyze
analyze:
	@mkdir -p $(OBJ_DIR)/cppcheck
	@cppcheck \
		--quiet \
		--enable=all \
		--suppress=missingIncludeSystem \
		--suppress=missingInclude \
		--suppress=selfAssignment \
		--suppress=cstyleCast \
		--suppress=unmatchedSuppression \
		--inconclusive \
		--check-level=exhaustive \
		--error-exitcode=1 \
		--cppcheck-build-dir=$(OBJ_DIR)/cppcheck \
		--template=gcc \
		-I include/ \
		-I src/ \
		src/

.PHONY: build
build: $(BIN_DIR)/$(BUILD)/$(PLATFORM)/$(BIN)$(BIN_EXT)

.PHONY: cdb
cdb:
	$(info )
	$(info === Build compile_commands.json ===)
	@compiledb -n make

.PHONY: clean
clean:
	$(info )
	$(info === CLEAN ===)
	rm -r $(OBJ_DIR)/* $(BIN_DIR)/*

.PHONY: debug
debug: cdb
	@$(MAKE) BUILD=debug build
	@$(MAKE) analyze

.PHONY: host
host:
	http-server -o . -c-1

.PHONY: init
init:
	mkdir -p assets include lib src
	touch src/main.cpp

.PHONY: publish
publish: 
	@$(MAKE) debug release web windows -j

.PHONY: release
release: 
	@$(MAKE) BUILD=release build

.PHONY: run
run:
	$(BIN_DIR)/$(BUILD)/$(PLATFORM)/$(BIN)$(BIN_EXT)

.PHONY: web
web:
	@$(MAKE) BUILD=release PLATFORM=web build

.PHONY: windows
windows:
	@$(MAKE) BUILD=release PLATFORM=windows build


#######################################
### Rules
#######################################
# === COMPILER COMMAND ===
# web files
$(OBJ_DIR)/$(BUILD)/$(PLATFORM)/%.cpp.o : %.cpp
# $(OBJ_DIR)/%.cpp.o: %.cpp 
	$(info )
	$(info === Compile: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	@mkdir -p $(dir $@)
	$(EMCC) -o $@ -c $< $(EMCXX_FLAGS) $(INC_FLAGS) 

# cpp files
$(OBJ_DIR)/$(BUILD)/$(PLATFORM)/%.cpp.o : %.cpp
# $(OBJ_DIR)/%.cpp.o: %.cpp 
	$(info )
	$(info === Compile: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	@mkdir -p $(dir $@)
	$(CXX) -o $@ -c $< $(CXX_FLAGS) $(INC_FLAGS)

# c files
$(OBJ_DIR)/$(BUILD)/$(PLATFORM)/%.c.o : %.c
# $(OBJ_DIR)/%.c.o: %.c 
	$(info )
	$(info === Compile: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	@mkdir -p $(dir $@)
	$(CC) -o $@ -c $< $(C_FLAGS) $(INC_FLAGS)


# === LINKER COMMAND ===
# windows bin
$(BIN_DIR)/$(BUILD)/windows/$(BIN)$(BIN_EXT): $(OBJS)
	$(info )
	$(info === Link: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	@mkdir -p $(dir $@)
	$(WINCXX) -o $@ $^ $(EMCXX_FLAGS) $(LIB_FLAGS) $(LD_FLAGS) 

# web bin
$(BIN_DIR)/$(BUILD)/web/$(BIN)$(BIN_EXT): $(OBJS)
	$(info )
	$(info === Link: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	@mkdir -p $(dir $@)
	$(EMCXX) -o $@ $^ $(EMCXX_FLAGS) $(LIB_FLAGS) $(LD_FLAGS) 

# unix bin
$(BIN_DIR)/$(BUILD)/unix/$(BIN)$(BIN_EXT): $(OBJS)
	$(info )
	$(info === Link: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	@mkdir -p $(dir $@)
	$(CXX) -o $@ $^ $(CXX_FLAGS) $(LIB_FLAGS) $(LD_FLAGS) 


### "-" surpresses error for initial missing .d files
-include $(DEPS)

info:
	$(info )
	$(info === INFO ===)
	@echo BIN : $(BIN)
	@echo SRC_DIR : $(SRC_DIR)
	@echo INC_DIR : $(INC_DIR)
	@echo LIB_DIR : $(LIB_DIR)
	@echo OBJ_DIR : $(OBJ_DIR)
	@echo BIN_DIR : $(BIN_DIR)
	@echo SRC_EXT : $(SRC_EXT)
	@echo INC_EXT : $(INC_EXT)
	@echo LIB_EXT : $(LIB_EXT)
	@echo BIN_EXT : $(BIN_EXT)
	@echo BUILD : $(BUILD)
	@echo PLATFORM : $(PLATFORM)
	@echo CXX : $(CXX)
	@echo MAKEFLAGS : $(MAKEFLAGS)
	@echo CXX_FLAGS : $(CXX_FLAGS)
	@echo SRCS : $(SRCS)
	@echo OBJS : $(OBJS)
	@echo DEPS : $(DEPS)
	@echo USR_DIR : $(USR_DIR)
	@echo USR_DIRS : $(USR_DIRS)
	@echo INC_DIRS : $(INC_DIRS)
	@echo INC_DIRS_SYS : $(INC_DIRS_SYS)
	@echo LIB_DIRS : $(LIB_DIRS)
	@echo INC_FLAGS : $(INC_FLAGS)
	@echo LIB_FLAGS : $(LIB_FLAGS)
	@echo LD_FLAGS : $(LD_FLAGS)
	@echo ASSETS_DIR : $(ASSETS_DIR)
