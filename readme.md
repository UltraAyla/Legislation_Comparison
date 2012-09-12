Legislation Comparison v2

The original version of this software was meant to take prerelease versions of legislation from PDFs and strip out the extra information from the PDF, then compare them. It was meant to be used by advocates who received copies of versions before they were in structured formats from the Library of Congress.

Version 2 was designed to be used for *different* bills which may share a common ancestor to find out which provisions were kept and which were removed. It outputs HTML files that go through the bills line by line and show a score for comparing that line with the best match from the other bill. Matches with scores below 50% are ignored.

Currently, this repository does not include the setup information or SQL create statements. This will be added in a future commit.