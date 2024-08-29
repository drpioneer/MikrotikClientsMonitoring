# Clients monitoring script
# Script uses ideas by drPioneer
# https://github.com/drpioneer/MikrotikClientsMonitoring/blob/main/monitor.rsc
# https://forummikrotik.ru/viewtopic.php?p=95254#p95254
# tested on ROS 6.49.15 & 7.14.3
# updated 2024/08/29

:local customClientList {
  {name="EBreHuu"; mac="00:00:00:00:00:00"};
  {name="rAJluHa"; mac="00:00:00:00:00:00"};
  {name="AHDpeu"; mac="00:00:00:00:00:00"};
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
  {name="PLC-adapter7"; mac="00:00:00:00:00:00"; ignor=true};
};                                                                                  # custom clients list
:global clients; :if ([len $clients]=0) do={:set $clients {name=[toarray ""];mac=[toarray ""];stat=[toarray 0];msg=[toarray false]}};
:local threshold 2;                                                                 # number of checks
:local Output do={:put $1; /log warn $1};                                           # information output function
:local idDev [/system identity get name];
:foreach dhcpLse in=[/ip dhcp-server lease find] do={                               
  :local dhcpMac [/ip dhcp-server lease get $dhcpLse mac-address];
  :local comment ""; :local ignor false;
  :foreach client in=$customClientList do={
    :if (($client->"mac")=$dhcpMac) do={
      :set $comment ($client->"name");
      :if ($client->"ignor") do={:set $ignor true}
    }
  }
  :if (!$ignor) do={
    :if ([len $comment]=0) do={:set $comment [/ip dhcp-server lease get $dhcpLse comment]};
    :if ([len $comment]=0) do={:set $comment [/ip dhcp-server lease get $dhcpLse host-name]};
    :if ([len $comment]=0) do={:set $comment $dhcpMac};
    :local hostMac ""; :do {:set $hostMac [/interface bridge host get [find mac-address=$dhcpMac] mac-address];} on-error={};
    :local index; :set $index [find ($clients->"mac") $dhcpMac];
    :if ([len $index]=0) do={                                                       # when client is not presented in base of clients ->
      :set $index ([len ($clients->"mac")]);                                        # last index for new client in base
      :set ($clients->"mac" ->$index) $dhcpMac;
      :set ($clients->"name"->$index) $comment;
      :if ([len $hostMac]=0) do={                                                   # when client is not presented in bridge hosts ->
        :local stringMsg "$index. --$($clients->"name"->$index) BHE 3OHbl '$idDev'";# client is 'outside the zone'
        [$Output $stringMsg];
        :set ($clients->"stat"->$index) $threshold;
        :set ($clients->"msg"->$index) false;
      } else={                                                                      # when client is presented in bridge hosts ->
        :local stringMsg "$index. ++$($clients->"name"->$index) OKOJlO '$idDev'";   # client is 'near'
        [$Output $stringMsg];
        :set ($clients->"stat"->$index) 0;
        :set ($clients->"msg"->$index) true;
      }
    } else={                                                                        # when client is presented in base of clients ->
      :if ([len $hostMac]=0) do={                                                   # when client is not presented in bridge hosts ->
        :if (($clients->"stat"->$index)=$threshold) do={                            # when client has status 'outside the zone' several times row ->
          :if (($clients->"msg"->$index)=true) do={                                 # when message 'outside the zone' was not sent ->
            :local stringMsg "-- $($clients->"name"->$index) BHE 3OHbl '$idDev'";   # client is 'outside the zone'
            [$Output $stringMsg];
            :set ($clients->"msg"->$index) false;                                   # message 'outside the zone' is sent
          }
        }
        :set ($clients->"stat"->$index) (($clients->"stat"->$index)+1);
        :if (($clients->"stat"->$index)>($threshold*5)) do={                        # when client has status 'outside the zone' several times row ->
          :set ($clients->"stat"->$index) $threshold;
        }
      } else={                                                                      # when client is presented in bridge hosts ->
        :if (($clients->"stat"->$index)>0) do={                                     # when client has status 'outside the zone' ->
          :if (($clients->"msg"->$index)=false) do={                                # when message 'near' was not sent ->
            :local stringMsg "++ $($clients->"name"->$index) OKOJlO '$idDev'";      # client is 'near'
            [$Output $stringMsg];
            :set ($clients->"stat"->$index) 0;
            :set ($clients->"msg"->$index) true;                                    # message 'near' is sent
          }
        }
      }
    }
  }
}
