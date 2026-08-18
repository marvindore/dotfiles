# Splunk SPL Cheat Sheet

## 1. SPL Mental Model

Most Splunk searches follow this pipeline:

1. Find events
2. Filter unnecessary events
3. Extract or calculate fields
4. Aggregate results
5. Format and present results

```spl
index=<index> sourcetype=<sourcetype> earliest=<time>
<filters>
| <field extraction>
| <transformation>
| <aggregation>
| <presentation>


Each pipe | sends the results from the command on its left to the command on its right.

2. Basic Search Structure
Search an index
index=application

Search by index and sourcetype
index=application sourcetype=api_logs

Search production hosts
index=application host=prod-*

Search for a text value
index=application "connection refused"

Search multiple terms
index=application error timeout


Both terms must be present.

Search an exact phrase
index=application "database connection timeout"

Exclude a term
index=application error NOT "expected error"

Search with OR
index=application (error OR exception OR failure)

Combine AND, OR, and NOT
index=application
(error OR exception)
NOT ("known issue" OR "health check")


Use parentheses whenever combining Boolean expressions.

3. Time Ranges

Whenever possible, use the time picker in Splunk Web. Explicit time ranges are also useful for saved searches and repeatable investigations.

Last 15 minutes
index=application earliest=-15m

Last hour
index=application earliest=-1h

Last 24 hours
index=application earliest=-24h

Today
index=application earliest=@d

Yesterday
index=application earliest=-1d@d latest=@d

Current week
index=application earliest=@w

Previous week
index=application earliest=-1w@w latest=@w

Absolute time range
index=application
earliest="08/13/2026:08:00:00"
latest="08/13/2026:09:00:00"

Common time modifiers
s = seconds
m = minutes
h = hours
d = days
w = weeks
mon = months
@h = beginning of the hour
@d = beginning of the day
@w = beginning of the week

Examples:

earliest=-30m
earliest=-4h
earliest=-7d
earliest=-1d@d latest=@d

4. Discovering Your Data
Count events by index

Requires appropriate permissions.

| eventcount summarize=false index=*
| stats sum(count) AS events by index
| sort - events

Find common sourcetypes
index=application earliest=-24h
| stats count by sourcetype
| sort - count

Find common sources
index=application earliest=-24h
| stats count by source
| sort - count

Find active hosts
index=application earliest=-24h
| stats count by host
| sort - count

Examine sample events
index=application earliest=-15m
| head 20

View raw events with selected metadata
index=application earliest=-15m
| table _time index sourcetype source host _raw

See available fields
index=application earliest=-15m
| head 100
| fieldsummary

5. Working with Fields
Show selected fields
index=application earliest=-1h
| fields _time host service status message

Remove fields
index=application earliest=-1h
| fields - source sourcetype

Display a table
index=application earliest=-1h
| table _time host service status message

Rename fields
index=application earliest=-1h
| rename response_time AS "Response Time"

Replace null values
index=application earliest=-1h
| fillnull value="Unknown" service status

Keep events where a field exists
index=application earliest=-1h
| where isnotnull(errorCode)

Keep events where a field does not exist
index=application earliest=-1h
| where isnull(errorCode)

List distinct values
index=application earliest=-24h
| stats values(service) AS services

Count distinct values
index=application earliest=-24h
| stats dc(userId) AS unique_users


dc() means distinct count.

6. Filtering Results
Filter before the first pipe when possible

Preferred:

index=application sourcetype=api_logs status=500 earliest=-1h


Less efficient in many situations:

index=application earliest=-1h
| where status=500

Filter numeric values
index=application earliest=-1h
| where duration_ms > 1000

Filter strings
index=application earliest=-1h
| where service="payment-api"

Match part of a string
index=application earliest=-1h
| where like(message, "%timeout%")


Wildcards for like():

% matches zero or more characters
_ matches one character
Filter using multiple conditions
index=application earliest=-1h
| where status>=500 AND duration_ms>1000

Filter values from a list
index=application earliest=-1h
| where status IN (500, 502, 503, 504)

Filter with search after a pipe
index=application earliest=-1h
| search service="payment-api" status>=500

7. Sorting, Limiting, and Deduplication
Sort highest to lowest
index=application earliest=-1h
| stats count by service
| sort - count

Sort lowest to highest
index=application earliest=-1h
| stats count by service
| sort count

Return the first 20 results
index=application earliest=-1h
| head 20

Return the last 20 results
index=application earliest=-1h
| tail 20

Keep one event per request ID
index=application earliest=-1h
| dedup requestId

Keep the latest event per request ID
index=application earliest=-1h
| sort 0 - _time
| dedup requestId


Use sort 0 to avoid the normal result limit applied by sort.

8. Statistics with stats
Count all matching events
index=application earliest=-1h
| stats count

Count by service
index=application earliest=-1h
| stats count by service

Count by multiple fields
index=application earliest=-1h
| stats count by service status

Basic response-time statistics
index=application earliest=-1h
| stats
    count
    min(duration_ms) AS min_ms
    avg(duration_ms) AS avg_ms
    median(duration_ms) AS median_ms
    max(duration_ms) AS max_ms
  by service

Calculate percentiles
index=application earliest=-1h
| stats
    avg(duration_ms) AS avg_ms
    perc95(duration_ms) AS p95_ms
    perc99(duration_ms) AS p99_ms
  by service

Get earliest and latest values
index=application earliest=-24h
| stats
    earliest(status) AS first_status
    latest(status) AS latest_status
  by requestId

Collect unique values
index=application earliest=-1h
| stats values(errorCode) AS error_codes by service

Collect values including duplicates
index=application earliest=-1h
| stats list(status) AS statuses by requestId


list() preserves duplicates and order but can create large results. Use it carefully.

9. Conditional Aggregation

Conditional aggregation is often more efficient and readable than separate searches or joins.

Count successes and errors
index=application earliest=-1h
| stats
    count AS total
    count(eval(status>=200 AND status<400)) AS successful
    count(eval(status>=500)) AS errors
  by service

Calculate error rate
index=application earliest=-1h
| stats
    count AS total
    count(eval(status>=500)) AS errors
  by service
| eval error_rate=round((errors/total)*100, 2)
| sort - error_rate

Avoid division by zero
index=application earliest=-1h
| stats
    count AS total
    count(eval(status>=500)) AS errors
  by service
| eval error_rate=if(total>0, round((errors/total)*100, 2), 0)

Count different error categories
index=application earliest=-1h
| stats
    count(eval(status=400)) AS bad_requests
    count(eval(status=401)) AS unauthorized
    count(eval(status=404)) AS not_found
    count(eval(status>=500)) AS server_errors
  by service

10. Calculated Fields with eval
Create a calculated field
index=application earliest=-1h
| eval duration_seconds=duration_ms/1000

Round a number
index=application earliest=-1h
| eval duration_seconds=round(duration_ms/1000, 2)

Categorize values
index=application earliest=-1h
| eval performance=case(
    duration_ms<500, "Fast",
    duration_ms<1000, "Normal",
    duration_ms<3000, "Slow",
    true(), "Very Slow"
  )

Use a simple condition
index=application earliest=-1h
| eval result=if(status>=500, "Error", "Success")

Create a value from the first non-null field
index=application earliest=-1h
| eval user=coalesce(userId, username, email, "Unknown")

Concatenate values
index=application earliest=-1h
| eval endpoint=method . " " . uri_path

Convert text to lowercase
index=application earliest=-1h
| eval service=lower(service)

Convert text to uppercase
index=application earliest=-1h
| eval environment=upper(environment)

String length
index=application earliest=-1h
| eval message_length=len(message)

Extract part of a string
index=application earliest=-1h
| eval short_id=substr(requestId, 1, 8)

11. Time-Based Analysis
Event count over time
index=application earliest=-24h
| timechart span=15m count

Errors over time by service
index=application earliest=-24h status>=500
| timechart span=15m count by service

Average response time over time
index=application earliest=-24h
| timechart span=15m avg(duration_ms) AS avg_ms

Average and p95 response time
index=application earliest=-24h
| timechart span=15m
    avg(duration_ms) AS avg_ms
    perc95(duration_ms) AS p95_ms

Error rate over time
index=application earliest=-24h
| timechart span=15m
    count AS total
    count(eval(status>=500)) AS errors
| eval error_rate=round((errors/total)*100, 2)

Group timestamps into buckets
index=application earliest=-24h
| bin _time span=15m
| stats count by _time service

12. JSON Logs with spath
Extract all discoverable JSON fields
index=application sourcetype=json_logs earliest=-1h
| spath

Extract a nested JSON field
index=application earliest=-1h
| spath path=service.name output=service_name

Extract an error message
index=application earliest=-1h
| spath path=error.message output=error_message

Extract from a specific JSON field
index=application earliest=-1h
| spath input=payload path=user.id output=user_id

Work with a JSON array
index=application earliest=-1h
| spath path=items{} output=items
| mvexpand items

Common JSON investigation
index=application earliest=-1h
| spath
| table _time service.name log.level error.code error.message

13. Regex Extraction with rex
Extract a request ID
index=application earliest=-1h
| rex field=_raw "requestId[=:\"\s]+(?<request_id>[A-Za-z0-9-]+)"

Extract an error code
index=application earliest=-1h
| rex field=_raw "errorCode[=:\"\s]+(?<error_code>[A-Z0-9_-]+)"

Extract from a specific field
index=application earliest=-1h
| rex field=message "user=(?<username>[^\s]+)"

Mask sensitive data in displayed results
index=application earliest=-1h
| rex mode=sed field=message "s/\b\d{16}\b/[REDACTED]/g"


Important: Search-time masking only changes the displayed search result. It does not remove the original value from indexed data.

Useful regex patterns
\d+              One or more digits
\w+              One or more word characters
\s+              One or more whitespace characters
\S+              One or more non-whitespace characters
[^,]+            One or more characters that are not commas
[A-Za-z0-9-]+    Letters, numbers, and hyphens
.*?              Non-greedy match


Named capture group syntax:

(?<field_name>pattern)

14. Multivalue Fields
Expand a multivalue field into separate results
index=application earliest=-1h
| mvexpand errorCodes

Count values in a multivalue field
index=application earliest=-1h
| eval error_count=mvcount(errorCodes)

Join multivalue values into a string
index=application earliest=-1h
| eval errors=mvjoin(errorCodes, ", ")

Select the first value
index=application earliest=-1h
| eval first_error=mvindex(errorCodes, 0)

Split a string into multiple values
index=application earliest=-1h
| eval tags=split(tag_list, ",")

Remove duplicate multivalue entries
index=application earliest=-1h
| eval unique_errors=mvdedup(errorCodes)

15. eventstats and streamstats
Add overall statistics to every event
index=application earliest=-1h
| eventstats avg(duration_ms) AS overall_avg
| eval difference_from_avg=duration_ms-overall_avg


Unlike stats, eventstats preserves the individual events.

Add group statistics to every event
index=application earliest=-1h
| eventstats avg(duration_ms) AS service_avg by service
| eval difference_from_service_avg=duration_ms-service_avg

Add a running count
index=application earliest=-1h
| sort 0 _time
| streamstats count AS event_number

Calculate a running average
index=application earliest=-1h
| sort 0 _time
| streamstats window=10 avg(duration_ms) AS moving_average

Compare with the previous event
index=application earliest=-1h
| sort 0 _time
| streamstats current=false last(duration_ms) AS previous_duration by service
| eval change=duration_ms-previous_duration

16. Lookups
Add lookup information
index=application earliest=-1h
| lookup service_owners.csv service OUTPUT owner team

Rename the matching lookup field
index=application earliest=-1h
| lookup service_owners.csv service_name AS service OUTPUT owner team

Find values missing from the lookup
index=application earliest=-1h
| lookup service_owners.csv service OUTPUT owner
| where isnull(owner)

Replace a search field using lookup output
index=application earliest=-1h
| lookup service_owners.csv service OUTPUTNEW owner team


OUTPUTNEW does not overwrite an existing non-null field.

Filter using a lookup
index=application earliest=-1h
[
  | inputlookup monitored_services.csv
  | fields service
]

View lookup contents
| inputlookup service_owners.csv

17. Combining Data
Combine related events using stats

This is usually preferred over join or transaction.

index=application earliest=-1h
| stats
    earliest(_time) AS started
    latest(_time) AS completed
    values(status) AS statuses
    values(message) AS messages
  by requestId
| eval duration_seconds=completed-started

Combine multiple event types
index=application earliest=-1h
(event_type=request OR event_type=response)
| stats
    earliest(_time) AS request_time
    latest(_time) AS response_time
    values(status) AS status
  by requestId
| eval duration_ms=(response_time-request_time)*1000

Use append to stack result sets
index=application environment=production earliest=-1h
| stats count AS events
| eval environment="Production"
| append [
    search index=application environment=test earliest=-1h
    | stats count AS events
    | eval environment="Test"
  ]

Use join cautiously
index=application sourcetype=requests earliest=-1h
| join type=left requestId [
    search index=application sourcetype=responses earliest=-1h
    | fields requestId status duration_ms
  ]


Prefer stats, lookups, or conditional aggregation when possible. Subsearches and joins can introduce result limits and performance issues.

Use transaction cautiously
index=application earliest=-1h
| transaction requestId maxspan=5m


transaction can consume substantial memory. Use it mainly when event order, boundaries, or raw grouped events are essential.

18. Comparing Time Periods
Compare current period with the previous period
index=application earliest=-2h latest=now
| eval period=if(_time>=relative_time(now(), "-1h"), "Current", "Previous")
| stats count by service period
| chart values(count) over service by period
| fillnull value=0
| eval change=Current-Previous
| eval percent_change=if(Previous>0, round((change/Previous)*100, 2), null())

Compare today with yesterday
index=application earliest=-1d@d latest=now
| eval period=if(_time>=relative_time(now(), "@d"), "Today", "Yesterday")
| eval comparison_time=if(period="Yesterday", _time+86400, _time)
| bin comparison_time span=1h
| stats count by comparison_time period


Be careful around daylight-saving-time changes when adding a fixed 86400 seconds.

19. Common Troubleshooting Searches
Top errors
index=application earliest=-1h
(error OR exception OR failure)
| stats count latest(message) AS latest_message by service errorCode
| sort - count
| head 20

Errors by service
index=application earliest=-1h status>=500
| stats count by service
| sort - count

Error trend
index=application earliest=-24h status>=500
| timechart span=15m count by service

Error rate by service
index=application earliest=-1h
| stats
    count AS total
    count(eval(status>=500)) AS errors
  by service
| eval error_rate=round((errors/total)*100, 2)
| sort - error_rate

Slow endpoints
index=application earliest=-1h
| stats
    count
    avg(duration_ms) AS avg_ms
    perc95(duration_ms) AS p95_ms
    max(duration_ms) AS max_ms
  by service endpoint
| where count>=10
| sort - p95_ms

Slow individual requests
index=application earliest=-1h duration_ms>1000
| table _time service endpoint duration_ms requestId status
| sort - duration_ms

Find an incident by correlation ID
index=application earliest=-24h
(requestId="REQUEST-ID" OR correlationId="REQUEST-ID" OR traceId="REQUEST-ID")
| sort 0 _time
| table _time host service log_level status message

Find affected hosts
index=application earliest=-1h error
| stats count latest(message) AS latest_message by host
| sort - count

Detect hosts that stopped sending data
index=application earliest=-24h
| stats latest(_time) AS last_event by host
| eval minutes_since_event=round((now()-last_event)/60, 1)
| where minutes_since_event>15
| convert ctime(last_event)
| sort - minutes_since_event

Traffic by endpoint
index=application earliest=-1h
| stats count by method endpoint
| sort - count

HTTP status summary
index=application earliest=-1h
| eval status_group=case(
    status>=200 AND status<300, "2xx",
    status>=300 AND status<400, "3xx",
    status>=400 AND status<500, "4xx",
    status>=500 AND status<600, "5xx",
    true(), "Other"
  )
| stats count by status_group
| sort status_group

Requests with no successful response
index=application earliest=-1h
| stats
    count(eval(event_type="request")) AS requests
    count(eval(event_type="response" AND status<500)) AS successful_responses
  by requestId
| where requests>0 AND successful_responses=0

Exception volume and latest example
index=application earliest=-24h exception
| stats
    count
    latest(_time) AS last_seen
    latest(message) AS example
  by exception_type
| convert ctime(last_seen)
| sort - count

20. Performance Tips
Filter as early as possible

Prefer:

index=application sourcetype=api_logs host=prod-* status>=500 earliest=-1h


Avoid searching all data and filtering later when an early filter is possible.

Start with a small time range

While building a search:

earliest=-15m


Expand the time range only after validating the logic.

Specify an index

Prefer:

index=application error


Avoid:

index=* error

Specify a sourcetype when known
index=application sourcetype=api_logs

Keep only required fields
index=application earliest=-1h
| fields _time service status duration_ms

Aggregate before sorting

Prefer:

index=application earliest=-1h
| stats count by service
| sort - count

Avoid unnecessary expensive commands

Use cautiously:

join
transaction
broad wildcard searches
unbounded regex
large subsearches
map
sort 0 on large datasets
mvexpand on large multivalue fields
Check search performance

After running a search:

Open the Job menu.
Select Inspect Job.
Review search processing duration.
Look for expensive commands.
Compare event counts before and after filters.
Verify that the search is limited by index and time.
21. Useful Formatting
Format timestamps
index=application earliest=-1h
| eval event_time=strftime(_time, "%Y-%m-%d %H:%M:%S")

Parse a timestamp
index=application earliest=-1h
| eval parsed_time=strptime(timestamp, "%Y-%m-%dT%H:%M:%S")

Convert epoch fields for display
index=application earliest=-1h
| convert ctime(start_time) ctime(end_time)

Format numbers
index=application earliest=-1h
| stats avg(duration_ms) AS avg_ms
| eval avg_ms=round(avg_ms, 2)

Create a chart-friendly label
index=application earliest=-1h
| eval label=service . " - " . environment

22. Useful SPL Functions
Numeric functions
round(value, 2)
ceil(value)
floor(value)
abs(value)
sqrt(value)

String functions
lower(field)
upper(field)
len(field)
trim(field)
substr(field, start, length)
replace(field, "pattern", "replacement")

Conditional functions
if(condition, true_value, false_value)
case(condition1, value1, condition2, value2, true(), default_value)
coalesce(field1, field2, field3)
null()

Null checking
isnull(field)
isnotnull(field)

Time functions
now()
relative_time(now(), "-1h")
strftime(_time, "%Y-%m-%d %H:%M:%S")
strptime(timestamp, "%Y-%m-%dT%H:%M:%S")

Statistical functions
count
sum(field)
avg(field)
min(field)
max(field)
median(field)
perc95(field)
perc99(field)
dc(field)
values(field)
latest(field)
earliest(field)

23. Search Development Workflow

Use this sequence when creating a new search.

Step 1: Start with metadata and time
index=application sourcetype=api_logs earliest=-15m

Step 2: Add a known filter
index=application sourcetype=api_logs earliest=-15m
(error OR exception)

Step 3: Inspect sample events
index=application sourcetype=api_logs earliest=-15m
(error OR exception)
| head 20

Step 4: Display useful fields
index=application sourcetype=api_logs earliest=-15m
(error OR exception)
| table _time host service requestId errorCode message

Step 5: Extract anything missing
index=application sourcetype=api_logs earliest=-15m
(error OR exception)
| rex field=_raw "errorCode=(?<error_code>[A-Z0-9_-]+)"

Step 6: Aggregate
index=application sourcetype=api_logs earliest=-15m
(error OR exception)
| stats count latest(message) AS example by service errorCode

Step 7: Sort and format
index=application sourcetype=api_logs earliest=-15m
(error OR exception)
| stats count latest(message) AS example by service errorCode
| sort - count
| head 20

Step 8: Expand the time range

After validating the search, change:

earliest=-15m


to the actual investigation window.

24. Reusable Search Template
index=<index>
sourcetype=<sourcetype>
host=<host-pattern>
earliest=<time-range>
(<term-1> OR <term-2>)
NOT (<noise-term-1> OR <noise-term-2>)
| fields _time host service requestId status duration_ms message
| eval result=if(status>=500, "Error", "Success")
| stats
    count AS total
    count(eval(result="Error")) AS errors
    avg(duration_ms) AS avg_ms
    perc95(duration_ms) AS p95_ms
    latest(message) AS latest_message
  by service
| eval error_rate=if(total>0, round((errors/total)*100, 2), 0)
| sort - error_rate

25. Personal Environment Reference

Fill this section in with your organization's information.

Common indexes
Production:
Non-production:
Infrastructure:
Security:
Network:
Kubernetes:
Windows:
Linux:
Common sourcetypes
Application logs:
API logs:
Web access logs:
Kubernetes logs:
Windows events:
Linux logs:
Common fields
Service:
Environment:
Host:
Request ID:
Correlation ID:
Trace ID:
User ID:
Status:
Error code:
Duration:
Endpoint:
Log level:
Useful lookups
Service owners:
Host inventory:
Application inventory:
Error-code descriptions:
Maintenance windows:
Saved searches
Error summary:
Service health:
Slow endpoints:
Missing hosts:
Incident investigation:
Error-rate trend:
26. Quick Command Reference
search filters events.
where filters using expressions and functions.
fields keeps or removes fields.
table displays fields as columns.
stats aggregates events into summary results.
eventstats adds aggregate values while preserving events.
streamstats calculates running or windowed statistics.
timechart creates time-based aggregates.
chart creates category-based tables suitable for charts.
eval calculates or transforms fields.
rex extracts fields using regular expressions.
spath extracts fields from JSON or XML.
lookup enriches events using lookup data.
dedup keeps one event per field value.
sort orders results.
head keeps the first results.
tail keeps the last results.
bin groups numeric or time values into buckets.
fillnull replaces null values.
rename changes field names.
mvexpand creates one result per multivalue entry.
append adds one result set below another.
join combines result sets by a shared field.
transaction groups related events into transactions.
```
