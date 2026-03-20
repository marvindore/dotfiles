# Advanced Nushell Examples for Power Users

## Searching
# Find lines containing 'error' in a log file
open logs.txt | find "error"

# Search for files with names matching a pattern
ls | where name =~ "^config.*\.json$"

## Sorting
# Sort processes by memory usage
^ps aux | lines | split-column " " user pid cpu mem command | sort-by mem | reverse

# Sort a list of versions naturally
["1.2.10", "1.2.2", "1.2.9"] | sort-by --natural

## Modifying Text
# Trim whitespace from all fields
open data.txt | lines | split-column ":" key value | update key {str trim $it.key} | update value {str trim $it.value}

# Replace text in a column
open data.txt | lines | split-column ":" key value | update value {str replace "foo" "bar" $it.value}

# Extract substring from a string
"Nushell is awesome" | str substring 0..7

## Filtering
# Filter users older than 30
open users.json | where age > 30

# Filter files larger than 10MB
ls | where size > 10mb

# Filter rows with multiple conditions
open data.csv | from csv | where status == "active" and score > 80

## Data Transformation
# Flatten nested JSON
open nested.json | flatten

# Group users by department
open users.json | group-by department

# Pivot a table
open sales.csv | from csv | pivot

# Merge two tables
let a = [{name: "Alice"}, {name: "Bob"}]
let b = [{age: 30}, {age: 25}]
$a | merge $b

# Rename columns
open data.csv | from csv | rename old_name new_name

# Add a new column with computed values
open data.csv | from csv | insert score_level {if $it.score > 80 {"high"} else {"low"}}

## Parsing External Output
# Parse output of a system command
^df -h | lines | parse "{filesystem} {size} {used} {avail} {use%} {mounted}"

# Parse structured text with regex
open report.txt | lines | parse -r "(?P<key>\w+): (?P<value>.+)"

