#!/usr/bin/env python3
#
# py_menu.py - Python-based TUI for Linux Setup with Categories
# Description: Enhanced menu system with categories, search, and better navigation
# Usage: ./py_menu.py
#

import os
import sys
import subprocess
import curses
from curses import wrapper
from pathlib import Path
import re

class InstallerMenu:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.installers_dir = self.script_dir / "installers"
        self.installers = self.discover_installers()
        self.categories = self.organize_by_category()
        self.current_view = "main"  # "main", "category", or "search"
        self.selected = 0
        self.offset = 0
        self.search_term = ""
        self.filtered_items = []
        self.current_category = None

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
                
            # Extract metadata from file header
            description = "No description"
            category = "Utilities"  # Default category
            
            try:
                with open(script_path, 'r') as f:
                    for line in f:
                        if line.startswith("# Description:"):
                            description = line.replace("# Description:", "").strip()
                        elif line.startswith("# Category:"):
                            category = line.replace("# Category:", "").strip()
                        # Break if we've passed the header comment section
                        elif line.strip() and not line.startswith("#"):
                            break
            except Exception:
                pass
                
            display_name = name.replace("setup_", "")
            installers.append({
                'name': display_name,
                'description': description,
                'category': category,
                'path': str(script_path)
            })
            
        return installers

    def organize_by_category(self):
        """Organize installers by category"""
        categories = {}
        
        # Add installers to their categories
        for installer in self.installers:
            cat = installer['category']
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(installer)
            
        # Sort categories and their contents
        for cat in categories:
            categories[cat].sort(key=lambda x: x['name'])
            
        # Sort categories alphabetically
        return dict(sorted(categories.items()))

    def get_current_items(self):
        """Get items to display based on current view"""
        if self.current_view == "search":
            return self.filtered_items
        elif self.current_view == "category":
            return self.categories.get(self.current_category, [])
        else:  # main view
            # Return categories with item counts
            items = []
            for category, installers in self.categories.items():
                items.append({
                    'type': 'category',
                    'name': category,
                    'description': f"{len(installers)} items",
                    'installers': installers
                })
            return items

    def filter_items(self):
        """Filter items based on search term"""
        if not self.search_term:
            self.filtered_items = []
            self.current_view = "main" if self.current_category is None else "category"
            return
            
        self.current_view = "search"
        all_items = []
        
        # In category view, only search within current category
        if self.current_category and self.current_category in self.categories:
            items_to_search = self.categories[self.current_category]
        else:
            # In main view, search all installers
            items_to_search = self.installers
            
        for item in items_to_search:
            if (self.search_term.lower() in item['name'].lower() or 
                self.search_term.lower() in item['description'].lower()):
                item_copy = item.copy()
                item_copy['type'] = 'installer'
                all_items.append(item_copy)
                
        self.filtered_items = all_items

    def draw_menu(self, stdscr):
        """Draw the menu interface"""
        height, width = stdscr.getmaxyx()
        
        # Clear screen
        stdscr.clear()
        
        # Title
        if self.current_view == "search":
            title = f"Search Results: '{self.search_term}'"
        elif self.current_view == "category":
            title = f"Category: {self.current_category}"
        else:
            title = "Linux Setup - Installation Menu"
            
        stdscr.addstr(0, (width - len(title)) // 2, title, curses.A_BOLD)
        stdscr.addstr(1, 0, "=" * width)
        
        # Breadcrumb navigation
        if self.current_view != "main":
            breadcrumb = "Main"
            if self.current_view == "category":
                breadcrumb += f" > {self.current_category}"
            if self.current_view == "search":
                breadcrumb += f" > Search"
            stdscr.addstr(2, 0, breadcrumb[:width-1])
            stdscr.addstr(3, 0, "-" * width)
            search_row = 4
        else:
            search_row = 2
            
        # Search bar
        search_prompt = f"Search: {self.search_term}"
        stdscr.addstr(search_row, 0, search_prompt[:width-1])
        stdscr.addstr(search_row + 1, 0, "-" * width)
        
        # Instructions
        if self.current_view == "main":
            instructions = "↑/↓: Navigate | Enter: Select | /: Search | q: Quit"
        elif self.current_view == "category":
            instructions = "↑/↓: Navigate | Enter: Select | /: Search | ←: Back | q: Quit"
        else:  # search view
            instructions = "↑/↓: Navigate | Enter: Select | ESC: Clear Search | ←: Back | q: Quit"
            
        stdscr.addstr(search_row + 2, 0, instructions[:width-1])
        stdscr.addstr(search_row + 3, 0, "-" * width)
        
        # Calculate visible items
        max_visible = height - (search_row + 6)  # Reserve space for header/footer
        if max_visible <= 0:
            return
            
        # Get current items to display
        items = self.get_current_items()
        
        # Adjust offset to keep selection visible
        if self.selected >= len(items):
            self.selected = max(0, len(items) - 1)
        if self.offset >= len(items):
            self.offset = max(0, len(items) - 1)
        if self.selected < self.offset:
            self.offset = self.selected
        elif self.selected >= self.offset + max_visible:
            self.offset = self.selected - max_visible + 1
            
        # Display items
        for i in range(max_visible):
            idx = self.offset + i
            if idx >= len(items):
                break
                
            item = items[idx]
            
            # Highlight selected item
            if idx == self.selected:
                attr = curses.A_REVERSE
            else:
                attr = curses.A_NORMAL
                
            # Format display based on item type
            if item.get('type') == 'category':
                line = f"📁 {item['name']:<20} - {item['description']}"
            elif item.get('type') == 'installer':
                line = f"⚙️  {item['name']:<20} - {item['description']}"
            else:
                # Default installer display in main/category view
                line = f"⚙️  {item['name']:<20} - {item['description']}"
                
            stdscr.addstr(search_row + 4 + i, 0, line[:width-1], attr)
            
        # Status line
        if items:
            status = f"Items: {len(items)} | Selected: {self.selected + 1}"
        else:
            status = "No items found"
        stdscr.addstr(height - 1, 0, status[:width-1], curses.A_BOLD)
        
        stdscr.refresh()

    def run_installer(self, stdscr, installer_path):
        """Run the selected installer"""
        stdscr.clear()
        height, width = stdscr.getmaxyx()
        
        installer_name = Path(installer_path).name
        stdscr.addstr(0, 0, f"Running: {installer_name}", curses.A_BOLD)
        stdscr.addstr(1, 0, "Installation in progress...")
        stdscr.addstr(2, 0, "Press Ctrl+C to cancel")
        stdscr.refresh()
        
        # End curses mode temporarily
        curses.endwin()
        
        # Run the installer
        try:
            result = subprocess.run(["bash", installer_path], check=True)
            success = True
        except subprocess.CalledProcessError as e:
            success = False
            print(f"Installation failed with exit code {e.returncode}")
        except KeyboardInterrupt:
            success = False
            print("Installation cancelled")
            
        # Show completion message
        if success:
            print("\n✅ Installation completed successfully!")
        else:
            print("\n❌ Installation failed or was cancelled.")
            
        input("\nPress Enter to return to menu...")
            
        # Restart curses mode
        stdscr = curses.initscr()
        curses.cbreak()
        stdscr.keypad(True)
        curses.noecho()
        
        return stdscr

    def navigate_back(self):
        """Navigate back to previous view"""
        if self.current_view == "search":
            self.search_term = ""
            self.current_view = "main" if self.current_category is None else "category"
            self.filtered_items = []
        elif self.current_view == "category":
            self.current_view = "main"
            self.current_category = None
        # In main view, back quits

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
                    items = self.get_current_items()
                    if items:
                        self.selected = min(self.selected + 1, len(items) - 1)
                elif key == curses.KEY_UP:
                    if self.get_current_items():
                        self.selected = max(self.selected - 1, 0)
                elif key == ord('\n') or key == curses.KEY_ENTER:
                    items = self.get_current_items()
                    if items and self.selected < len(items):
                        item = items[self.selected]
                        
                        if self.current_view == "main" and item.get('type') == 'category':
                            # Enter category
                            self.current_view = "category"
                            self.current_category = item['name']
                            self.selected = 0
                            self.offset = 0
                        elif item.get('type') == 'installer' or 'path' in item:
                            # Run installer
                            installer_path = item.get('path', '')
                            if installer_path:
                                stdscr = self.run_installer(stdscr, installer_path)
                elif key == curses.KEY_LEFT or key == ord('h') or key == ord('H'):
                    # Navigate back
                    self.navigate_back()
                    self.selected = 0
                    self.offset = 0
                elif key == ord('/'):
                    # Enter search mode
                    self.search_term = ""
                    self.filter_items()
                elif key in [curses.KEY_BACKSPACE, 127, 8]:
                    if self.search_term:
                        self.search_term = self.search_term[:-1]
                        self.filter_items()
                elif key == 27:  # ESC key
                    if self.current_view == "search":
                        self.search_term = ""
                        self.current_view = "main" if self.current_category is None else "category"
                        self.filtered_items = []
                    else:
                        self.navigate_back()
                        self.selected = 0
                        self.offset = 0
                elif 32 <= key <= 126:  # Printable characters
                    self.search_term += chr(key)
                    self.filter_items()
                    
            except KeyboardInterrupt:
                break

def main():
    """Main entry point"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("Linux Setup Menu - Python TUI with Categories")
        print("Usage: ./py_menu.py")
        print("Navigation:")
        print("  Arrow keys - Move selection")
        print("  Enter - Select category/run installer")
        print("  / - Start search mode")
        print("  ←/h - Go back to previous menu")
        print("  ESC - Clear search/go back")
        print("  q - Quit menu")
        return
        
    menu = InstallerMenu()
    try:
        wrapper(menu.run)
    except Exception as e:
        print(f"Error running menu: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()