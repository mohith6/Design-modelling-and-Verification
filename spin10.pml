mtype = { T1, T2, A, B, C, D, E, F, Stop, Go, Clear, Blocked };  // Signal types for better control

#define max_trains_in_tunnel 1  // Maximum number of trains allowed in a tunnel at a time

chan TunnelAB = [max_trains_in_tunnel] of { mtype };
chan TunnelBC = [max_trains_in_tunnel] of { mtype };
chan TunnelCD = [max_trains_in_tunnel] of { mtype };
chan TunnelDA = [max_trains_in_tunnel] of { mtype };

chan signalboxAB = [0] of { byte };
chan signalboxBC = [0] of { byte };
chan signalboxCD = [0] of { byte };
chan signalboxDA = [0] of { byte };

chan St_SgBoxA = [0] of { byte };
chan St_SgBoxB = [0] of { byte };
chan St_SgBoxC = [0] of { byte };
chan St_SgBoxD = [0] of { byte };

chan Sgb_StA = [0] of { byte };
chan Sgb_StB = [0] of { byte };
chan Sgb_StC = [0] of { byte };
chan Sgb_StD = [0] of { byte };

// Station process - manages train entry, exit, and signaling
proctype Station(chan exit_tunnel, enter_tunnel, Request, Response; byte ntrains) {
    byte train;
    bool TrackSideSig = false;  // Track-side signal status (Go, Stop, Clear, Blocked)

    do
    :: exit_tunnel?train -> 
        Request!A;  // Request to leave station (enter tunnel)
        ntrains++;   // Increase the train count when it exits
        
    :: (ntrains > 0) -> 
        // Proceed based on track-side signal (Go or Clear)
        if
        ::(TrackSideSig == Go || TrackSideSig == Clear) -> 
            Request!B; enter_tunnel!train; ntrains--;  // Move the train into the tunnel and update the count
        ::(TrackSideSig == Stop || TrackSideSig == Blocked) -> 
            Request!C;  // Request a signal change if the train cannot proceed
        fi;
        
        // Receive track-side signal response to update train status
        Response?TrackSideSig;
    od
}

// SignalBox process - handles signaling logic (Go, Stop, Clear, Blocked)
proctype SignalBox(chan st_Response, st_Request, signalbox_adv, signalbox_rear) {
    bool Empty = true;  // Track state (True if track is empty, False if occupied)
    byte n;

    do
    :: st_Response?n ->
        if
        ::(n == A) -> 
            signalbox_rear!D;  // Signal track is empty
        ::(n == B) -> 
            Empty = false; 
            st_Request!Go;  // Track is occupied, send 'Go' signal if allowed
        ::(n == C) ->
            if
            ::(Empty == true) -> 
                st_Request!Clear;  // Track is clear, send 'Clear' signal
            ::else -> 
                st_Request!Blocked;  // Track is blocked, send 'Blocked' signal
            fi;
        fi;
        
    :: signalbox_adv?n ->
        if
        ::(n == D) -> 
            Empty = true;  // Reset track state to empty when a train departs
        fi;
    od;
}

// Setup process to introduce trains into the tunnels
proctype Setup(chan tunnel; byte train) {
    tunnel!train;  // Introduce a train into the tunnel
}

// Safety process to ensure tunnels do not hold more than 1 train at a time
active proctype safety() {
    assert (len(TunnelAB) <= max_trains_in_tunnel);
    assert (len(TunnelBC) <= max_trains_in_tunnel);
    assert (len(TunnelCD) <= max_trains_in_tunnel);
    assert (len(TunnelDA) <= max_trains_in_tunnel);
}

// Integrity check to ensure no tunnel is overbooked
active proctype integrity_check() {
    bool track_clear;
    track_clear = (len(TunnelAB) < max_trains_in_tunnel && 
                   len(TunnelBC) < max_trains_in_tunnel && 
                   len(TunnelCD) < max_trains_in_tunnel && 
                   len(TunnelDA) < max_trains_in_tunnel);
    assert(track_clear);  // Ensure that no tunnel is overbooked
}

// Initialization of the system
init {
    atomic {
        run Setup(TunnelBC, T1);  // Introduce train T1 before station C
        run Setup(TunnelDA, T2);  // Introduce train T2 before station A
        
        run Station(TunnelDA, TunnelAB, St_SgBoxA, Sgb_StA, 0);  // Station A
        run Station(TunnelAB, TunnelBC, St_SgBoxB, Sgb_StB, 1);  // Station B
        run Station(TunnelBC, TunnelCD, St_SgBoxC, Sgb_StC, 0);  // Station C
        run Station(TunnelCD, TunnelDA, St_SgBoxD, Sgb_StD, 1);  // Station D
        
        run SignalBox(St_SgBoxA, Sgb_StA, signalboxDA, signalboxAB);
        run SignalBox(St_SgBoxB, Sgb_StB, signalboxAB, signalboxBC);
        run SignalBox(St_SgBoxC, Sgb_StC, signalboxBC, signalboxCD);
        run SignalBox(St_SgBoxD, Sgb_StD, signalboxCD, signalboxDA);
        
        run integrity_check();  // Ensure no tunnel is overbooked before starting
    }
}

// LTL Properties for safety and liveness
ltl a {
    [] (len(TunnelAB) <= max_trains_in_tunnel && len(TunnelBC) <= max_trains_in_tunnel && 
        len(TunnelCD) <= max_trains_in_tunnel && len(TunnelDA) <= max_trains_in_tunnel)  // Safety condition
}

ltl b {
    [](len(TunnelAB) == 0 || len(TunnelBC) == 0 || len(TunnelCD) == 0 || len(TunnelDA) == 0) -> 
    [](len(TunnelAB) < max_trains_in_tunnel && len(TunnelBC) < max_trains_in_tunnel &&
       len(TunnelCD) < max_trains_in_tunnel && len(TunnelDA) < max_trains_in_tunnel)  // Ensure tunnels are not overcrowded
}

ltl c {
    [] (SignalBoxStatus == Go || SignalBoxStatus == Clear || SignalBoxStatus == Blocked || SignalBoxStatus == Stop) // Ensure valid signal states
}
