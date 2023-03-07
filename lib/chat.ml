module Message = struct
(** Message module to define chat message type *)
  
  (** Content inside a message *)
  type contents ={
    message   : string; (** Message sent by user *)
    sent_time : float;  (** Timestamp when message was sent *)
  }

  type t = A of contents | M of contents
  (** Acknowledgment (A) or regular (M) message type *)
  (** Message type with some content. Can be an acknowledgment or a regular message *)


  let string_of_content c =
    let sst = Printf.sprintf "%.15g" (c.sent_time) in
    sst ^ "|" ^ c.message


  let content_of_string s = 
    let div_i = String.index_from s 0 '|' in
    let sent_time = float_of_string (String.sub s 1 (div_i-1))
    and message = String.sub s (div_i+1) ((String.length s) - (div_i+1)) in
    {sent_time = sent_time; message = message}


  let string_of_message = function
    | M c -> "M" ^ string_of_content c
    | A c -> "A" ^ string_of_content c


  let message_of_string s = 
    match s.[0] with
    | 'M' -> M (content_of_string s)
    | 'A' -> A (content_of_string s)
    | _   -> failwith "Bad message type."

  
  let get_ack_time c_time c = 
    (c_time) -. c.sent_time

end


open Lwt.Infix
open Message


(** Prints messages from the terminal to the output channel of the socket *)
let rec output_promise output_channel = 
  Lwt_io.read_line Lwt_io.stdin >>= function
  | "/quit" -> Lwt.return_unit
  | s when (String.length s) > 0 && s.[0] = '/' -> Lwt_io.printl "Unknown command." >>= fun () -> output_promise  output_channel
  | s ->
    string_of_message (M {message = s; sent_time = Unix.gettimeofday ()}) |> 
    Lwt_io.write_line output_channel >>= fun () -> output_promise output_channel


(** Reads messages from the input channel of the socket, and takes two actions based on the message type: 
      * if it receives an acknowledgment (A), it prints the content of the message along with the round-trip time (RTT); 
      * if it receives a regular message (M), it simply prints the message. *)
let rec input_promise input_channel output_channel =
  let send_ack c = 
    string_of_message (A c) |> 
    Lwt_io.write_line output_channel 
  in
  Lwt_io.read_line_opt input_channel >>= (function | None -> Lwt.return_unit | Some s ->  message_of_string s |> function
  | M c -> 
    send_ack c >>= fun () -> 
    Lwt_io.printl ("< " ^ c.message) >>= fun () ->
    input_promise input_channel output_channel
  | A c -> 
    let rtt = get_ack_time (Unix.gettimeofday ()) c in
    Lwt_io.printl ("$ Message delivered!\n * Content: " ^ c.message ^ "\n * RTT: " ^ (string_of_float rtt)) >>= fun () ->
    input_promise input_channel output_channel)


(** Function that starts a chat session with the desired address *)
let start_session (server_socket, server_address) = 
  Print.chat_header server_address;
  let input_channel   = Lwt_io.of_fd ~mode:Lwt_io.Input server_socket in
  let output_channel  = Lwt_io.of_fd ~mode:Lwt_io.Output server_socket in
  let op = output_promise output_channel in
  let ip = input_promise input_channel output_channel in
  Lwt.pick [ip; op] >>= fun () -> Lwt.return_unit




