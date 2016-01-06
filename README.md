# calutil
Command line utility to bulk-delete iCloud calendar events on OS X 10.9 or later.

About
---

###Why bulk-delete iCloud calendar events?

The total number of calandars, events and reminders on iCloud can not exceed 25,000. 

https://support.apple.com/en-us/HT202158

Applications that depend on iCloud data sync might have to do some regular house keeping to make sure the number of records under control. 

This command-line tool allows one to do the following:

* Count the number of events stored on iCloud calendars
* Delete old events stored on iCloud calendars

Syntax
---

```
calutil list
```

List all iCloud calendars.

```
calutil reset
```

Prompt the user to allow access to calendars from the Console app. When an unregistered app requests access, the user is asked to grant or deny access to that app. Once denied access, it won't ask the user again. This option allows you to re-grant access to the Console if it has been revoked (i.e. listed but unchecked).

![](https://github.com/miyako/calutil/blob/master/images/denied.png)

**Note**: This option can be used in conjunction with other options.

```
calutil count
```

Count all events on all iCloud calendars for the past 10 years. Events with recurrence rules are excluded.

**Note**: Apparently there is a bug in 10.9 Yosemite where an event with an incomplete recurrence rule is reported as recurring. Such events typically are missing the "repeat" option in the Calendar app. As a consequence, those events are not counted (and can not be deleted) using this program on Yosemite.

![](https://github.com/miyako/calutil/blob/master/images/no-recurrence.png)

Such events contain a recurrence ID like ``RECURRENCE-ID;TZID=Asia/Tokyo:20150320T113000`` in its vcard (ics) format, but no recurrence rule.

```
calutil count 5 year|month|day
```

Count all events on all iCloud calendars for the past 5 years/months/days.

```
calutil count 5 year|month|day 2 keep
```

Count all events on all iCloud calendars going back 5 years/months/days, starting from 2 years/months/days earlier. i.e. -7 to -2 years/months/days from yesterday. The unit for ``keep`` inherits from the range sepecification.

```
calutil count 1 year 2 month-keep
```

Same as above, but specify the range unit for ``keep``; -14 to -2 months from yesterday. The program counts in bulks of the range unit, as [EventKit](https://developer.apple.com/library/watchos/documentation/EventKit/Reference/EventKitFrameworkRef/index.html) fails with queries predicates that are too broad. The advantage of ``count 1 year 2 month-keep`` is that only 1 search is needed, as opposed to ``count 12 month 2 keep`` which requires 12 searches.

```
calutil delete 1 year 2 month-keep
```

Delete the events. A comfirmation prompt is displayed prior to the procedure. The events are deleted in a transaction, after which a final comfirmation prompt is displayed whether to commit.

```
calutil delete|count 1 year 2 month-keep except [calendar names]
```

Specify the name of calendars to exclude from the count/delete operation. Calendar names with spaces or special characters should be quote par regular command like options.

