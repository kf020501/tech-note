# MySQL Tips

## viewの作成

`create view view名 as select文` で作成する。

以下はSyslogサーバで作成した例

```sql
-- ログを再視診順に表示
create view Syslog.newlog as select ID, ReceivedAt, DeviceReportedTime, Facility, Priority, FromHost, SysLogTag, Message, InfoUnitID from Syslog.SystemEvents order by ReceivedAt desc;

-- 全体のアクセスログを表示
create view Syslog.accesselog as select ID, ReceivedAt, DeviceReportedTime, Facility, Priority, FromHost, SysLogTag, Message, InfoUnitID from Syslog.SystemEvents where SysLogTag like 'sshd%'order by ReceivedAt desc;
```
