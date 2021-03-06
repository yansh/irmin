(*
 * Copyright (c) 2014 Thomas Gazagnaire <thomas@gazagnaire.org>
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

module Log = Log.Make(struct let section = "WATCH" end)

open Core_kernel.Std
open Lwt

module type S = sig
  type key
  type value
  type t
  val notify: t -> key -> value option -> unit
  val create: unit -> t
  val clear: t -> unit
  val watch: t -> key -> value option -> value Lwt_stream.t
  val listen_dir: t -> string
    -> key:(string -> key option)
    -> value:(key -> value option Lwt.t)
    -> unit
end

let listen_dir_hook =
  ref (fun _dir _fn -> ())

let set_listen_dir_hook fn =
  listen_dir_hook := fn

module Make (K: IrminKey.S) (V: sig type t end) = struct

  type key = K.t
  type value = V.t

  type t = (int * value option * (value option -> unit)) list K.Table.t

  let create () =
    K.Table.create ()

  let clear t =
    K.Table.clear t

  let unwatch t key id =
    let ws = match Hashtbl.find t key with
      | None    -> []
      | Some ws -> ws in
    let ws = List.filter ~f:(fun (x,_,_) -> x <> id) ws in
    match ws with
    | [] -> Hashtbl.remove t key
    | ws -> Hashtbl.replace t ~key ~data:ws

  let notify t key value =
    Log.debugf "notify %s" (K.to_string key);
    match Hashtbl.find t key with
    | None    -> ()
    | Some ws ->
      let ws = List.map ws ~f:(fun (id, old_value, f as w) ->
          if old_value <> value then (
            Log.debugf "firing watch %s:%d" (K.to_string key) id;
            try f value; (id, value, f)
            with e ->
              unwatch t key id;
              raise e
          ) else w
        ) in
      Hashtbl.replace t ~key ~data:ws

  let id =
    let c = ref 0 in
    fun () -> incr c; !c

  let watch t key value =
    Log.debugf "watch %s" (K.to_string key);
    let stream, push = Lwt_stream.create () in
    let id = id () in
    Hashtbl.add_multi t ~key ~data:(id, value, push);
    stream

  let listen_dir (t:t) dir ~(key:string -> key option) ~(value:key -> value option Lwt.t) =
    !listen_dir_hook dir (fun file ->
        Log.debugf "listen_dir_hook: %s" file;
        match key file with
        | None     -> return_unit
        | Some key ->
          value key >>= fun value ->
          notify t key value;
          return_unit
      )
end
