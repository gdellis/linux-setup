#!/usr/bin/env python3
#
# py_menu.py - Python-based TUI for Linux Setup
# Description: Enhanced menu system with search and better navigation
# Usage: ./py_menu.py
#

import os
import sys
import subprocess
import curses
from curses import wrapper
from pathlib import Path

class InstallerMenu:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.installers_dir = self.script_dir / "installers"
        self.installers = self.discover_installers()
        self.selected = 0
        self.offset = 0
        self.search_term = ""
        self.filtered_installers = self.installers

    def discover_installers(self):
        """Discover all setup_*.sh scripts"""
        installers = []
        
        if not self.installers_dir.exists():
            return installers
            
        for script_path in sorted(self.installers_dir.glob("setup_*.sh")):
            # Skip special scripts
            name = script_path.stem
            if name in ["setup_gum", "setup_new_installer"]:
                continue
                
            # Extract description from file header
            description = "No description"
            try:
                with open(script_path, 'r') as f:
                    for line in f:
                        if line.startswith("# Description:"):
                            description = line.replace("# Description:", "").strip()
                            break
            except Exception:
                pass
                
            display_name = name.replace("setup_", "")
            installers.append({
                'name': display_name,
                'description': description,
                'path': str(script_path)
            })
            
        return installers

    def filter_installers(self):
        """Filter installers based on search term"""
        if not self.search_term:
            self.filtered_installers = self.installers
        else:
            self.filtered_installers = [
                inst for inst in self.installers 
                if self.search_term.lower() in inst['name'].lower() or 
                   self.search_term.lower() in inst['description'].lower()
            ]
        
        # Reset selection if needed
        if self.selected >= len(self.filtered_installers):
            self.selected = max(0, len(self.filtered_installers) - 1)
        if self.offset >= len(self.filtered_installers):
            self.offset = max(0, len(self.filtered_installers) - 1)

    def draw_menu(self, stdscr):
        """Draw the menu interface"""
        height, width = stdscr.getmaxyx()
        
        # Clear screen
        stdscr.clear()
        
        # Title
        title = "Linux Setup - Installation Menu"
        stdscr.addstr(0, (width - len(title)) // 2, title, curses.A_BOLD)
        stdscr.addstr(1, 0, "=" * width)
        
        # Search bar
        search_prompt = f"Search: {self.search_term}"
        stdscr.addstr(2, 0, search_prompt[:width-1])
        stdscr.addstr(3, 0, "-" * width)
        
        # Instructions
        instructions = "↑/↓: Navigate | Enter: Select | /: Search | q: Quit"
        stdscr.addstr(4, 0, instructions[:width-1])
        stdscr.addstr(5, 0, "-" * width)
        
        # Calculate visible items
        max_visible = height - 8  # Reserve space for header/footer
        if max_visible <= 0:
            return
            
        # Adjust offset to keep selection visible
        if self.selected < self.offset:
            self.offset = self.selected
        elif self.selected >= self.offset + max_visible:
            self.offset = self.selected - max_visible + 1
            
        # Display installers
        for i in range(max_visible):
            idx = self.offset + i
            if idx >= len(self.filtered_installers):
                break
                
            installer = self.filtered_installers[idx]
            
            # Highlight selected item
            if idx == self.selected:
                attr = curses.A_REVERSE
            else:
                attr = curses.A_NORMAL
                
            # Format display
            line = f"{installer['name']:<20} - {installer['description']}"
            stdscr.addstr(6 + i, 0, line[:width-1], attr)
            
        # Status line
        status = f"Items: {len(self.filtered_installers)}/{len(self.installers)} | Selected: {self.selected + 1}"
        stdscr.addstr(height - 1, 0, status[:width-1], curses.A_BOLD)
        
        stdscr.refresh()

    def run_installer(self, stdscr, installer_path):
        """Run the selected installer"""
        stdscr.clear()
        height, width = stdscr.getmaxyx()
        
        stdscr.addstr(0, 0, f"Running: {Path(installer_path).name}", curses.A_BOLD)
        stdscr.addstr(1, 0, "Press any key to continue after installation...")
        stdscr.refresh()
        
        # End curses mode temporarily
        curses.endwin()
        
        # Run the installer
        try:
            subprocess.run(["bash", installer_path], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Installation failed with exit code {e.returncode}")
        except KeyboardInterrupt:
            print("Installation cancelled")
            
        # Restart curses mode
        stdscr = curses.initscr()
        curses.cbreak()
        stdscr.keypad(True)
        curses.noecho()
        
        stdscr.addstr(2, 0, "Press any key to return to menu...")
        stdscr.getch()
        
        return stdscr

    def run(self, stdscr):
        """Main menu loop"""
        # Setup curses
        curses.curs_set(0)  # Hide cursor
        stdscr.keypad(True)
        curses.noecho()
        
        while True:
            self.draw_menu(stdscr)
            
            try:
                key = stdscr.getch()
                
                if key == ord('q') or key == ord('Q'):
                    break
                elif key == curses.KEY_DOWN:
                    if self.filtered_installers:
                        self.selected = min(self.selected + 1, len(self.filtered_installers) - 1)
                elif key == curses.KEY_UP:
                    if self.filtered_installers:
                        self.selected = max(self.selected - 1, 0)
                elif key == ord('\n') or key == curses.KEY_ENTER:
                    if self.filtered_installers:
                        installer = self.filtered_installers[self.selected]
                        stdscr = self.run_installer(stdscr, installer['path'])
                        # Redraw after installer returns
                elif key == ord('/'):
                    # Enter search mode
                    self.search_term = ""
                    self.filter_installers()
                    # Simple search input (could be enhanced)
                elif key in [curses.KEY_BACKSPACE, 127, 8]:
                    if self.search_term:
                        self.search_term = self.search_term[:-1]
                        self.filter_installers()
                elif key == 27:  # ESC key
                    self.search_term = ""
                    self.filter_installers()
                elif 32 <= key <= 126:  # Printable characters
                    self.search_term += chr(key)
                    self.filter_installers()
                    
            except KeyboardInterrupt:
                break

def main():
    """Main entry point"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("Linux Setup Menu - Python TUI")
        print("Usage: ./py_menu.py")
        print("Navigation: Arrow keys to move, Enter to select, 'q' to quit")
        return
        
    menu = InstallerMenu()
    try:
        wrapper(menu.run)
    except Exception as e:
        print(f"Error running menu: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()