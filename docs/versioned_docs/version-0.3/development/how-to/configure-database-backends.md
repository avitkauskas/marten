---
title: Configure database backends
description: How to configure database backends.
---

This guide provides instructions on configuring new database backends or changing the existing database backend within your existing Marten projects.

## Context

Marten officially supports **MySQL**, **PostgreSQL**, and **SQLite3** databases. New Marten projects default to utilizing a SQLite3 database, a lightweight serverless database application that is typically pre-installed on most existing operating systems. This makes it an excellent choice for a development or testing database, but you may want to use a more powerful database such as MySQL or PostgreSQL. In this light, this guide explains what steps should be taken in order to use your database backend of choice in a Marten project.

## Prerequisites

This guide presupposes that you already have a functional Marten project available. If you don't, you can easily create one using the following command:

```bash
marten new project
```

Furthermore, it assumes that your preferred database is properly configured and ready for use. If this isn't the case, please consult the respective official documentation to install your chosen database:

* [PostgreSQL Installation Guide](https://wiki.postgresql.org/wiki/Detailed_installation_guides)
* [MySQL Installation Guide](https://dev.mysql.com/doc/refman/8.0/en/installing.html)
* [SQLite Installation Guide](https://www.tutorialspoint.com/sqlite/sqlite_installation.htm)

## Installing the right database shard

For each database, a dedicated Crystal shard is required. Depending on your chosen database, you must include one of the following entries in your project's `shard.yml` file:

* [crystal-pg](https://github.com/will/crystal-pg) (required for PostgreSQL databases)
* [crystal-mysql](https://github.com/crystal-lang/crystal-mysql) (required for MySQL databases)
* [crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) (required for SQLite3 databases)

This means that your `shard.yml` file should resemble one of the following examples:

### MySQL

```yaml
name: myproject
version: 0.1.0

dependencies:
  marten:
    github: martenframework/marten
  // highlight-next-line
  mysql:
  // highlight-next-line
    github: crystal-lang/crystal-mysql
```

### PostgreSQL

```yaml
name: myproject
version: 0.1.0

dependencies:
  marten:
    github: martenframework/marten
  // highlight-next-line
  pg:
  // highlight-next-line
    github: will/crystal-pg
```

### SQLite3

```yaml
name: myproject
version: 0.1.0

dependencies:
  marten:
    github: martenframework/marten
  // highlight-next-line
  sqlite3:
  // highlight-next-line
    github: crystal-lang/crystal-sqlite3
```

## Adding the right DB Crystal requirement

After you've included the correct Crystal shard in your project's `shard.yml` file, the subsequent task is to add the corresponding requirement in the `src/project.cr` file. This file contains all the requirements of your project (including Marten itself) and is automatically generated by the [`new`](../reference/management-commands#new) management command.

Please consult the examples below to determine which requirement you should include based on your selected database backend:

### MySQL

```crystal
# Third party requirements.
require "marten"
// highlight-next-line
require "mysql"

# Project requirements.
# [...]

# Configuration requirements.
# [...]
```

### PostgreSQL

```crystal
# Third party requirements.
require "marten"
// highlight-next-line
require "pg"
```

### SQLite3

```crystal
# Third party requirements.
require "marten"
// highlight-next-line
require "sqlite3"
```

## Configuring your database

The last step involves configuring database settings so that they target the database you intend to use with your Marten project. While a comprehensive list of configuration options is available in the [Database settings reference](../reference/settings#database-settings), the following sections offer example configurations tailored to each supported database backend.

### MySQL

```crystal
config.database do |db|
  db.backend = :mysql
  db.host = "localhost"
  db.name = "my_db"
  db.user = "my_user"
  db.password = "insecure"
end
```

### PostgreSQL

```crystal
config.database do |db|
  db.backend = :postgresql
  db.host = "localhost"
  db.name = "my_db"
  db.user = "my_user"
  db.password = "insecure"
end
```

### SQLite3

```crystal
config.database do |db|
  db.backend = :sqlite
  db.name = "my_db.db"
end
```
