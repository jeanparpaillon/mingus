# Developers guide

Mingus is a DevOps platform. As such, it provides services like: DNS,
network management, load balancing, application deployment and
orchestration, git server, monitoring, user management, etc.

Unlike many other DevOps platforms, Mingus does not try to plug
together heterogeneous components through configuration of hazardous
configuration files. Mingus is based on a well defined, unified, data
model the above components have been built around for using this
unique data model.

## Data Model

### Data model at a glance

All items (applications, users, machines, networks) are
*resources*. *Resources* are instances of a *kind*, which defines a
list of attributes with their type, default value, arity and such.

*Resources* can be linked together with so-called... *links*. *Links*
also are instances of a *kind* and have always specific attributes:
* *source* is the URI of a *resource*,
* *target* can be any URI.

*Resources* and *links* are identified by an *id* which is an URI
(usually URL).

*Resources* and *links* can be extended with *mixins*. *Mixins* can be
declared at creation time or dynamically added/removed after
creation. *Mixins*, like *kinds*, define attributes and can also
overrides existing ones. They can be used, for instance, to override
default value or arity of an attribute.

*Mixins* without any attribute can be used to _tag_ *resources* (or
*links*).

Both *kind* and *mixin* are *categories*. *Categories* are defined by
an URL of the form: *<scheme>#<term>*, for instance:
*http://schemas.ogf.org/occi/infrastructure#compute*.

### In details

Data model is comprehensively defined in
the
[OCCI specifications](https://www.ogf.org/documents/GFD.221.pdf). Many
other resources about OCCI are available on
the [OCCI working group website](http://occi-wg.org) like:
* [JSON rendering](http://ogf.org/documents/GFD.226.pdf)
* *Categories* definitions for infrastructure items: compute,
  storage, network, OS
  in [OCCI Infrastructure](http://ogf.org/documents/GFD.224.pdf)
* ...

### Categories

Mingus categories are defined in `Mg.Model`.
