Storing annotations
===================

A common requirement of any annotation application is storage: namely, the
ability to save annotations to a remote server when they are created, and the
ability to query that same server at some later date in order to retrieve the
stored annotations.

Annotator currently ships with one storage adapter, ``annotator.storage.http``,
which talks to a JSON HTTP API described in :doc:`http-api`.

.. toctree::
   :glob:
   :maxdepth: 1

   *
