# open_xml Easy Data patch

This directory contains a minimal vendored copy of open_xml 0.3.1 under its
original Apache-2.0 license.

Easy Data patch version: 0.3.1+easydata.1

The upstream spreadsheet reader queried OOXML elements by qualified tag name.
Valid workbooks that use an explicit SpreadsheetML prefix, such as x:sheet and
x:worksheet, therefore produced an empty worksheet list.

The local patch makes workbook, relationship, worksheet, row, cell, and shared
string discovery compare XmlName.local. It also resolves absolute targets such
as /xl/worksheets/sheet1.xml and avoids duplicating the xl/ prefix.

Remove this path dependency when an upstream release includes equivalent
namespace-independent parsing and the regression fixture passes unchanged.
