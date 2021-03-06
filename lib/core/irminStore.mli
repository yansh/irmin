(*
 * Copyright (c) 2013-2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Signatures. *)

open Core_kernel.Std

module type RO = sig

  (** Read-only store. *)

  type t
  (** Type a store. *)

  type key
  (** Type of keys. *)

  type value
  (** Type of values. *)

  val create: unit -> t Lwt.t
  (** Create a store handle. The operation can be used multiple times
      as it is supposed to be very cheap (and usually
      non-blocking). *)

  val read: t -> key -> value option Lwt.t
  (** Read a value from the store. *)

  val read_exn: t -> key -> value Lwt.t
  (** Read a value from the store. Raise [Unknown k] if [k] does not
      have an associated value. *)

  val mem: t -> key -> bool Lwt.t
  (** Check if a key exists. *)

  val list: t -> key list -> key list Lwt.t
  (** Return all the keys that are allowed to access, knowing a given
      collection of keys (which might be seen as a passwords). *)

  val dump: t -> (key * value) list Lwt.t
  (** Return the store contents. *)

end

module type RO_BINARY = RO with type key = string and type value = Bigstring.t
(** Read-only store which associate strings to bigstrings. *)

module type AO = sig

  (** {2 Append-only Stores} *)

  include RO

  val add: t -> value -> key Lwt.t
  (** Write the contents of a value to the store. That's the
      responsibility of the append-only store to generate a consistent
      key. *)

end

module type AO_BINARY = AO with type key = string and type value = Bigstring.t
(** Append-only store which associate strings to big arrays. *)

module type RW = sig

  (** Mutable store. *)

  include RO

  val update: t -> key -> value -> unit Lwt.t
  (** Replace the contents of [key] by [value] if [key] is already
      defined and create it otherwise. *)

  val remove: t -> key -> unit Lwt.t
  (** Remove the given key. *)

  val watch: t -> key -> value Lwt_stream.t
  (** Watch a given key. *)

end

module type RW_BINARY = RW with type key = string and type value = Bigstring.t
(** read-write store which associate strings to big arrays. *)

module type S = sig

  (** A branch-consistent store is a mutable store which supports
      fork/join operations. *)

  include RW

  type branch
  (** Branch can be either a tag name or a commit hash. In the later
      case, the branch is said to be in a 'detached' state. *)

  type origin
  (** Provenance trackers. *)

  val create: ?branch:branch -> unit -> t Lwt.t
  (** Create a store handle. The default branch, if not set, is
      [Tag.master]. *)

  val detach: t -> unit Lwt.t
  (** Detach the current branch (ie. it is not assiaciated to a tag
      name anymore). *)

  val branch: t -> branch option
  (** Return the branch of the given store handle. *)

  val branch_exn: t -> branch
  (** Same as [branch] but raise [Not_found] in case of a detached
      head. *)

  val set_branch: t -> branch -> unit
  (** Update the current branch name. *)

  val update: t -> ?origin:origin -> key -> value -> unit Lwt.t
  (** Same as [RW.update] but with an optional [origin]
      argument to keep track of provenance. *)

  val remove: t -> ?origin:origin -> key -> unit Lwt.t
  (** Same as [RW.remove] but with an optional [origin]
      argument to keep track of provenance. *)

  val clone: t -> branch -> t option Lwt.t
  (** Fork the store, using the given branch name. Return [None] if the
      branch already exists. *)

  val clone_force: t -> branch -> t Lwt.t
  (** Same as [clone] but delete and update the existing branch if a
      branch with the same name already exists. *)

  val switch: t -> branch -> unit Lwt.t
  (** Switch the database contents the be same as the contents of the
      given branch. The two branches are still independant. *)

  val merge: t -> ?origin:origin -> branch -> unit IrminMerge.result Lwt.t
  (** [merge db t] merges the branch [t] into the current database
      branch. The two branches are still independant. *)

  val merge_exn: t -> ?origin:origin -> branch -> unit Lwt.t
  (** Same as [merge] but raise [Conflict "<msg>"] in case of a
      conflict. *)

end
