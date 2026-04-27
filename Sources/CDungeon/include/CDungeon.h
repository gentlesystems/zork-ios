/* CDungeon.h — public umbrella header for the CDungeon Swift module.
 *
 * Replaces the Xcode-style ZorkIOS-Bridging-Header.h. SPM auto-generates a
 * module map exposing this header to Swift importers via `import CDungeon`.
 */

#pragma once

/* Configure pipe fds before calling run_dungeon().
 * out_write_fd: game output will be written here (Swift reads from the other end).
 * in_read_fd:   game input will be read from here (Swift writes to the other end). */
void configure_dungeon_io(int out_write_fd, int in_read_fd);

/* Start the game; returns when the game ends. Must be called on a background thread. */
void run_dungeon(void);

/* Set to 1 by our exit() shim before longjmp; readable after run_dungeon() returns. */
extern volatile int dungeon_exited;
