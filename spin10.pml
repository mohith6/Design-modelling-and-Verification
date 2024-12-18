mtype = { T1, T2, A, B, C, D, E, F }
#define party (len(TunnelAB) < 2 && len(TunnelBC) < 2 && len(TunnelCD) < 2 && len(TunnelDA)  < 2);
chan TunnelAB = [2] of { mtype };
chan TunnelBC = [2] of { mtype };
chan TunnelCD = [2] of { mtype };
chan TunnelDA = [2] of { mtype };
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
proctype Station(chan exit_tunnel, enter_tunnel, Request, Response ; byte ntrains)
{
    byte train;
    bool m;
    bool TrackSideSig = false;
        do
//:: exit_tunnel?train; enter_tunnel!train;
:: exit_tunnel?train -> Request!A; ntrains++;
   
    :: (ntrains > 0) ->
        if
        ::(TrackSideSig == true) -> Request!B; enter_tunnel!train; ntrains--;
        ::(TrackSideSig == false) ->Request!C;
        fi;
        Response?m;
        if
        ::(m == 1) -> TrackSideSig = true;
        ::(m == 0) -> TrackSideSig = false;
        fi;
od
}
proctype SignalBox(chan st_Response, st_Request, signalbox_adv, signalbox_rear)
{
    bool Empty = true;
    bool n;
    do
    ::st_Response?n
        if
        ::(n == A) -> signalbox_rear!D;
        ::(n == B) -> Empty = false; st_Request!F;
        ::(n == C) ->
            if
            ::(Empty == true) -> st_Request!E;
            ::else -> st_Request!F;
            fi
        fi;
    ::signalbox_adv?n
        if
        ::(n == D) -> Empty = true;
        fi;
    od;
}
proctype Setup(chan tunnel; byte train)
{
tunnel!train;
}
active proctype safety()
{
    assert ((len(TunnelAB) < 2 && len(TunnelBC) < 2 && len(TunnelCD) < 2 && len(TunnelDA) < 2));
}
init {  atomic{
        run Setup(TunnelBC, T1); /* introduce train T1 before station C */
        run Setup(TunnelDA, T2); /* introduce train T2 before station A */
        run Station(TunnelDA, TunnelAB, St_SgBoxA, Sgb_StA, 0);   /* station A */
        run Station(TunnelAB, TunnelBC, St_SgBoxB, Sgb_StB, 1);   /* station B */
run Station(TunnelBC, TunnelCD, St_SgBoxC, Sgb_StC, 0);   /* station C */
        run Station(TunnelCD, TunnelDA, St_SgBoxD, Sgb_StD, 1);  /* station D */
        run SignalBox(St_SgBoxA, Sgb_StA, signalboxDA, signalboxAB);
        run SignalBox(St_SgBoxB, Sgb_StB, signalboxAB, signalboxBC);
        run SignalBox(St_SgBoxC, Sgb_StC, signalboxBC, signalboxCD);
        run SignalBox(St_SgBoxD, Sgb_StD, signalboxCD, signalboxDA);
	}
}
ltl a { always party }

