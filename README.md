# GNU make
## Find multiple file extensions (`find`)
```make
$(shell find $(DIR) -name '*.c' -or -name '*.cpp')`
```

## Find multiple file extensions (`rwildcard`)
```make
# Usage: $(call rwildcard,.dir1 .dir2,.ext1 .ext2)
rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2)$(filter $(addprefix %,$2),$d))`
```

## Target specific variables
```make
all: VAR = val
all:
	echo $(VAR)
```

## Compile to build directory (static pattern)
```make
OBJS:=$(OBJ_DIR)/$(SRCS:.c=.o)

$(OBJS) : $(OBJ_DIR)/%.o : %.c
```
