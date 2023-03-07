(** Prints an address *)
let address = function
  | Unix.ADDR_INET (ip, port) ->
      print_endline ((Unix.string_of_inet_addr ip) ^ ":" ^ (string_of_int port))
  | _ -> failwith "Invalid client address"


(** Prints the chat header and the address that the app is connected to *)
let chat_header server_address =
  let _ = Sys.command "clear" in 
  print_endline "╔════════════════════╗";
  print_endline "║                    ║";
  print_string  "║     Chat Room      ║ Connected to: "; address server_address;
  print_endline "║                    ║";
  print_endline "╚════════════════════╝"
