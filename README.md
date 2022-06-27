# Simplify logs to help understand them (winget)

## Description

If you ever done `winget <command> --verbose-logs` and then look at the log created, you have probably noticed that these logs are not so easy to read.

For me, logs repeat too many lines or contain to many details that do not really help you understand what is happening behind the curtains.

So, I decided to create this script to make logs more readable, what it does is remove what I consider unnecessary lines and format others in a way that you understand better what the deal is with all the information that it collects. You can easily see this difference just by looking at the size of the original log versus the one created by this script, is Megabytes smaller.

### Purpose

Make verbose logs more readable by helping understand the most important things that `winget list` does without having to deeply understand all the overwhelming information that the logs contain.

### How to run it

Make sure your system has permission for running scripts. Enter this in your powershell terminal.

> Set-ExecutionPolicy RemoteSigned

**Running process**
1. Download the powershell script into your system.
2. In a powershell terminal, `cd` into the script directory.
3. Enter `. .\wingetSimplifyLogs` in the terminal.

### See also

- [winget-ProgramList](https://github.com/shyguyCreate/winget-ProgramList) - Basic understanding of where `winget list` search for programs.
- [winget-GetProperties](https://github.com/shyguyCreate/winget-GetProperties) - Transform `winget` output columns into real properties.
