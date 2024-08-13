# Clients monitoring script
# Script uses ideas by drPioneer
# https://github.com/drpioneer/MikrotikClientsMonitoring/blob/main/monitor.rsc
# https://forummikrotik.ru/viewforum.php?f=14
# tested on ROS 6.49.15 & 7.14.3
# updated 2024/08/13

:local clientList {
  {name="EBreHuu"; mac="01:02:03:04:05:06"};
  {name="rAJluHa"; mac="10:20:30:40:50:60"};
  {name="MapuR"; mac="11:22:33:44:55:66"};
  {name="AHDPEu"; mac="06:05:04:03:02:01"};
  {name="Erop"; mac="60:50:40:30:20:10"};
  {name="DaHuuJl"; mac="66:55:44:33:22:11"};
  {name="DMuTpuu"; mac="01:00:02:00:03:00"};
  {name="AJleKcaHDp"; mac="02:00:03:00:04:00"};
  {name="TaTbRHa"; mac="03:00:04:00:05:00"};
  {name="6opuc"; mac="04:00:05:00:06:00"};
};                                                                                  # manual clients list
:global clients; :if ([len $clients]=0) do={:set $clients {name=[:toarray ""];mac=[:toarray ""];stat=[:toarray ""]}};
:local Output do={:put $1; /log warn $1};                                           # information output function
:local idDevice [/system identity get name];
:foreach dhcpLse in=[/ip dhcp-server lease find] do={                               
  :local dhcpMac [/ip dhcp-server lease get $dhcpLse mac-address];
  :local comment "";
  :foreach client in=$clientList do={:if (($client->"mac")=$dhcpMac) do={:set $comment ($client->"name")}}
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
