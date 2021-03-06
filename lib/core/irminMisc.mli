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

open Core_kernel.Std

(** Miscellaneous functions *)

val is_valid_utf8: string -> bool
(** Check whether a string is valid UTF8 encoded. *)

val json_encode: string -> Ezjsonm.t
(** Convert a (possibly non-valid UTF8) string to a JSON object.*)

val json_decode: Ezjsonm.t -> string option
(** Convert a JSON object to a (possibly non-valid UTF8)
    string. Return [None] if the JSON object is not a valid string. *)

val json_decode_exn: Ezjsonm.t -> string
(** Convert a JSON object to a (possibly non-valid UTF8) string. *)

val hex_encode: string -> string
(** Encode a binary string to hexa *)

val hex_decode: string -> string
(** Decode an hexa string to binary *)

val pretty_list: ('a -> string) -> 'a list -> string
(** Pretty-print a list. *)

val read: 'a Bin_prot.Type_class.t -> Bigstring.t -> 'a option
(** Try to read a buffer. *)

val write: 'a Bin_prot.Type_class.t -> 'a -> Bigstring.t
(** Write in a fresh buffer. *)

val lift_stream: 'a Lwt_stream.t Lwt.t -> 'a Lwt_stream.t
(** Lift a stream out of the monad. *)

module Map: sig

  (** Extensions to the [Map] module to handle blocking functions. *)

  val merge: ('k, 'v1, 'cmp) Map.t -> ('k, 'v2, 'cmp) Map.t ->
    f:(key:'k -> [ `Both of 'v1 * 'v2 | `Left of 'v1 | `Right of 'v2 ] -> 'v3 option Lwt.t) ->
    ('k, 'v3, 'cmp) Map.t Lwt.t
    (** Same as [Map.merge]. *)

  val iter2: ('k, 'v1, 'cmp) Map.t -> ('k, 'v2, 'cmp) Map.t ->
    f:(key:'k ->data:[ `Both of 'v1 * 'v2 | `Left of 'v1 | `Right of 'v2 ] -> unit Lwt.t) ->
    unit Lwt.t
    (** Same as [Map.iter2]. *)

end

val replace: pattern:string -> (string -> string) -> string -> string
(** Replace a pattern in a string. *)
