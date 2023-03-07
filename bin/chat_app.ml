open Lwt_unix
open Lwt.Infix

(** Default host *)
let host = ref "127.0.0.1"

(** Default port *)
let port = ref 8000

(** Default server mode *)
let server_mode = ref true

(** Change server mode based on symbol given *)
let change_mode = function
  | "s" -> ()
  | "c" -> server_mode := false
  | _   -> failwith "Invalid mode. Please try again with 'c' or 's'"


(** Change default settings based on program arguments *)
let update_from_args () = 
  let usage_msg = "SYNOPSIS: main.exe [-h <ip address>] [-p <port number>] [-m <mode of Operation]" in
  let speclist  = 
    [
      ("-h", Arg.Set_string host, "Set the IP address the application tries to connect to. Default is: 127.0.0.1.");
      ("-p", Arg.Set_int port, "Set the port the aplication tries to connect to. Default is: 8000.");
      ("-m", Arg.Symbol (["c"; "s"], change_mode), "Set the mode the application starts on. Default is server.");
  ] in
  Arg.parse speclist (fun _ -> ()) usage_msg


(** Client main function *)
let client server_socket server_address =
  Lwt.catch
  (
    fun () ->
    let _ = Sys.command "clear" in 
    print_string "Client is connecting to: "; Print.address server_address;
    print_endline "Waiting for server...";

    connect server_socket server_address >>= fun () ->
    Chat.start_session (server_socket, server_address) >>= fun () ->
    close server_socket
  )
  (function
  | Unix.Unix_error (Unix.ECONNREFUSED, _, _) -> 
    (print_endline "Error! Could not connect to server. Please try again...";
    close server_socket)

  | exn -> Lwt.fail exn
  )


(** Server main function *)
let server server_socket server_address = 
  let rec server_loop () =

    let _ = Sys.command "clear" in 
    print_string "Server is on: "; Print.address server_address;
    print_endline "Waiting for a client...";

    accept server_socket >>= Chat.start_session >>= server_loop 
  in
  Lwt.catch
  (fun () -> 
    let _ = Sys.command "clear" in 
    print_string "Server is starting on: "; Print.address server_address;

    bind server_socket server_address >>= fun () ->
    listen server_socket 1;
    server_loop () 
  )
  (function 
  | Unix.Unix_error (Unix.EADDRINUSE, _, _) -> 
    (print_endline "Error! Port already in use. Shutting down server...";
    close server_socket)

  | Unix.Unix_error (Unix.EBADF, _, _) -> 
    print_endline "Error! Could not accept connection. Please try again...";
    close server_socket

  | exn -> (close server_socket >>= (fun () -> Lwt.fail exn))
  )



let () =

  update_from_args ();

  let server_socket   = socket PF_INET SOCK_STREAM 0 in
  let server_address  = ADDR_INET (Unix.inet_addr_of_string !host, !port) in
  Lwt_main.run(
    if !server_mode then 
      server server_socket server_address
    else 
      client server_socket server_address
  )

