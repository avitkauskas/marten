---
hide_title: true
pagination_prev: null
pagination_next: null
slug: /
title: Prologue
---

import logo from "./static/img/prologue/logo.png";

<div
  style={{
    margin: "20px",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
  }}
>
  <img src={logo} alt="logo" style={{ width: "200px", height: "215px" }} />
</div>
<div
  style={{
    marginBottom: "80px",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
  }}
>
  <h2>
    Welcome to the <i>Marten</i> documentation!
  </h2>
</div>

**Marten** is a Crystal Web framework that enables pragmatic development and rapid prototyping. It provides a consistent and extensible set of tools that developers can leverage to build web applications without reinventing the wheel.

## Getting started

Are you new to the Marten web framework? The following resources will help you get started:

* The [installation guide](./getting-started/installation.md) will help you install Crystal and the Marten CLI
* The [tutorial](./getting-started/tutorial.md) will help you discover the main features of the framework by creating a simple web application

## Browsing the documentation

The Marten documentation contains multiple pages and references that don't necessarily serve the same purpose. To help you browse this documentation, here is an overview of the different sorts of content you might encounter:

* **Topic-specific guides** discuss the key concepts of the framework. They provide explanations and useful information about things like [models](./models-and-databases), [handlers](./handlers-and-http), and [templates](./templates)
* **Reference pages** provide a curated technical reference of the framework APIs
* **How-to guides** document how to solve common problems when working with the framework. Those can cover things like deployments, app development, etc

Additionally, an automatically-generated [API reference](pathname:///api/dev/index.html) is also available to dig into Marten's internals.
