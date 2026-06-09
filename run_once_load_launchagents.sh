#!/bin/bash
launchctl unload ~/Library/LaunchAgents/com.supercmd.bookmarks-watcher.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.supercmd.bookmarks-watcher.plist
launchctl unload ~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.supercmd.url-builder-watcher.plist
