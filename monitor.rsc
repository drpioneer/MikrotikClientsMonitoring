# Clients monitoring script
# Script uses ideas by drPioneer
# https://github.com/drpioneer/MikrotikClientsMonitoring/blob/main/monitor.rsc
# https://forummikrotik.ru/viewforum.php?f=14
# tested on ROS 6.49.15 & 7.14.3
# updated 2024/08/14

:local manualClientsList {
  {name="EBreHuu"; mac="00:00:00:00:00:00";};
  {name="rAJluHa"; mac="00:00:00:00:00:00"};
  {name="Erop"; mac="00:00:00:00:00:00"};
  {name="DaHuuJl"; mac="00:00:00:00:00:00"};
  {name="DMuTpuu"; mac="00:00:00:00:00:00"};
  {name="AJleKcaHDp"; mac="00:00:00:00:00:00"};
  {name="TaTbRHa"; mac="00:00:00:00:00:00"};
  {name="MeteoStation"; mac="00:00:00:00:00:00"; ignor=true};
  {name="PLC-adapter1"; mac="00:00:00:00:00:00"; ignor=true};
  {name="PLC-adapter2"; mac="00:00:00:00:00:00"; ignor=true};
  {name="PLC-adapter3"; mac="00:00:00:00:00:00"; ignor=true};
  {name="PLC-adapter4"; mac="00:00:00:00:00:00"; ignor=true};
  {name="PLC-adapter5"; mac="00:00:00:00:00:00"; ignor=true};
  {name="PLC-adapter6"; mac="00:00:00:00:00:00"; ignor=true};
};                                                                                  # manual clients list
:global clients; :if ([len $clients]=0) do={:set $clients {name=[:toarray ""];mac=[:toarray ""];stat=[:toarray ""]}};
:local Output do={:put $1; /log warn $1};                                           # information output function
:local idDevice [/system identity get name];
:foreach dhcpLse in=[/ip dhcp-server lease find] do={                               
  :local dhcpMac [/ip dhcp-server lease get $dhcpLse mac-address];
  :local comment ""; :local ignor false;
  :foreach client in=$manualClientsList do={
    :if (($client->"mac")=$dhcpMac) do={
      :set $comment ($client->"name");
      :if ($client->"ignor") do={:set $ignor true;}
    }
  }
  :if (!$ignor) do={
    :if ([len $comment]=0) do={:set $comment [/ip dhcp-server lease get $dhcpLse comment]};
    :if ([len $comment]=0) do={:set $comment [/ip dhcp-server lease get $dhcpLse host-name]};
    :if ([len $comment]=0) do={:set $comment $dhcpMac};
    :local hostMac ""; :do {:set $hostMac [/interface bridge host get [find mac-address=$dhcpMac] mac-address];} on-error={};
    :local indxMac; :set $indxMac [find ($clients->"mac") $dhcpMac];
    :if ([len $hostMac]!=0) do={                                                      # client is presented in bridge hosts ->
      :if ([len $indxMac]=0) do={                                                     # client is not presented in list of clients ->
        :set $indxMac ([len ($clients->"mac")]);
        :set ($clients->"mac" ->$indxMac) $dhcpMac;
        :set ($clients->"name"->$indxMac) $comment;
        :set ($clients->"stat"->$indxMac) "true";
        :local stringMsg "+++ $($clients->"name"->$indxMac) OKOJlO '$idDevice'";      # client is near
        [$Output $stringMsg];
      } else={                                                                        # client is presented in list of clients ->
        :if (($clients->"stat"->$indxMac)="false") do={                               # client has inactive status ->
          :set ($clients->"mac" ->$indxMac) $dhcpMac;
          :set ($clients->"name"->$indxMac) $comment;
          :set ($clients->"stat"->$indxMac) "true";
          :local stringMsg "+++ $($clients->"name"->$indxMac) OKOJlO '$idDevice'";    # client is near
          [$Output $stringMsg];
        }
      }
    } else={                                                                          # client is not presented in bridge hosts ->
      :if ([len $indxMac]=0) do={                                                     # client is not presented in list of clients ->
        :set $indxMac ([len ($clients->"mac")]);
        :set ($clients->"mac" ->$indxMac) $dhcpMac;
        :set ($clients->"name"->$indxMac) $comment;
        :set ($clients->"stat"->$indxMac) "false";
        :local stringMsg "--- $($clients->"name"->$indxMac) BHE 3OHbl '$idDevice'";   # client is outside the zone
        [$Output $stringMsg];
      } else={                                                                        # client is presented in list of clients ->
        :if (($clients->"stat"->$indxMac)="true") do={                                # client has active status ->
          :set ($clients->"mac" ->$indxMac) $dhcpMac;
          :set ($clients->"name"->$indxMac) $comment;
          :set ($clients->"stat"->$indxMac) "false";
          :local stringMsg "--- $($clients->"name"->$indxMac) BHE 3OHbl '$idDevice'"; # client is outside the zone
          [$Output $stringMsg];
        }
      }
    }
  }
}

