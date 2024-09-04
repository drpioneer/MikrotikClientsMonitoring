# Clients monitoring script
# Script uses ideas by rextended drPioneer
# https://github.com/drpioneer/MikrotikClientsMonitoring/blob/main/monitor.rsc
# https://forummikrotik.ru/viewtopic.php?p=95254#p95254
# tested on ROS 6.49.15 & 7.14.3
# updated 2024/09/04

:local timeThreshold 15;                                                            # threshold time in minutes to out of zone device
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
};                                                                                  # custom clients list
:global clients; :if ([len $clients]=0) do={:set $clients {name=[toarray ""];mac=[toarray ""];time=[toarray 0];msg=[toarray false]}};
:local Output do={:put $1; /log warn $1};                                           # information output function
:local T2U do={                            # time translation function to UNIX time # https://forum.mikrotik.com/viewtopic.php?t=75555#p994849
  :local dTime [:tostr $1]; :local yesterDay false;
  /system clock;
  :local cYear [get date]; :if ($cYear~"....-..-..") do={:set cYear [:pick $cYear 0 4]} else={:set cYear [:pick $cYear 7 11]}
  :if ([:len $dTime]=10 or [:len $dTime]=11) do={:set dTime "$dTime 00:00:00"}
  :if ([:len $dTime]=15) do={:set dTime "$[:pick $dTime 0 6]/$cYear $[:pick $dTime 7 15]"}
  :if ([:len $dTime]=14) do={:set dTime "$cYear-$[:pick $dTime 0 5] $[:pick $dTime 6 14]"}
  :if ([:len $dTime]=8) do={:if ([:totime $1]>[get time]) do={:set yesterDay true}; :set dTime "$[get date] $dTime"}
  :if ([:tostr $1]="") do={:set dTime ("$[get date] $[get time]")}
  :local vDate [:pick $dTime 0 [:find $dTime " " -1]]; :local vTime [:pick $dTime ([:find $dTime " " -1]+1) [:len $dTime]];
  :local vGmt [get gmt-offset]; :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}; :if ($vGmt<0) do={:set vGmt ($vGmt*-1)}
  :local arrMn [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]; :local vdOff [:toarray "0,4,5,7,8,10"];
  :local month [:tonum [:pick $vDate ($vdOff->2) ($vdOff->3)]];
  :if ($vDate~".../../....") do={
    :set vdOff [:toarray "7,11,1,3,4,6"];
    :set month ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $vDate ($vdOff->2) ($vdOff->3)] -1]/2);
    :if ($month>12) do={:set month ($month-12)}}
  :local year [:pick $vDate ($vdOff->0) ($vdOff->1)];
  :if ((($year-1968)%4)=0) do={:set ($arrMn->1) -1; :set ($arrMn->2) 30}
  :local toTd ((($year-1970)*365)+(($year-1968)/4)+($arrMn->$month)+([:pick $vDate ($vdOff->4) ($vdOff->5)]-1));
  :if ($yesterDay) do={:set toTd ($toTd-1)}; # bypassing ROS6.xx time format problem after 00:00:00
  :return (((((($toTd*24)+[:pick $vTime 0 2])*60)+[:pick $vTime 3 5])*60)+[:pick $vTime 6 8]-$vGmt);
}
:local U2T do={                           # time conversion function from UNIX time # https://forum.mikrotik.com/viewtopic.php?p=977170#p977170
  :local ZeroFill do={:return [:pick (100+$1) 1 3]}
  :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"];
  :local vGmt [:tonum [/system clock get gmt-offset]];
  :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}
  :if ($vGmt<0) do={:set vGmt ($vGmt*-1)}
  :local tzEpoch ($vGmt+[:tonum $1]);
  :if ($tzEpoch<0) do={:set tzEpoch 0}; # unsupported negative unix epoch
  :local yearStamp (1970+($tzEpoch/31536000));
  :local tmpLeap (($yearStamp-1968)/4);
  :if ((($yearStamp-1968)%4)=0) do={:set ($prMntDays->1) -1; :set ($prMntDays->2) 30}
  :local tmpSec ($tzEpoch%31536000);
  :local tmpDays (($tmpSec/86400)-$tmpLeap);
  :if ($tmpSec<(86400*$tmpLeap) && (($yearStamp-1968)%4)=0) do={
    :set tmpLeap ($tmpLeap-1); :set ($prMntDays->1) 0; :set ($prMntDays->2) 31; :set tmpDays ($tmpDays+1)}
  :if ($tmpSec<(86400*$tmpLeap)) do={:set yearStamp ($yearStamp-1); :set tmpDays ($tmpDays+365)}
  :local mnthStamp 12; :while (($prMntDays->$mnthStamp)>$tmpDays) do={:set mnthStamp ($mnthStamp-1)}
  :local dayStamp [$ZeroFill (($tmpDays+1)-($prMntDays->$mnthStamp))];
  :local timeStamp (00:00:00+[:totime ($tmpSec%86400)]);
  :if ([:len $2]=0) do={:return "$yearStamp/$[$ZeroFill $mnthStamp]/$[$ZeroFill $dayStamp] $timeStamp"} else={:return [:pick $timeStamp 0 5]}
}
:local idDev [/system identity get name];
:set $timeThreshold ($timeThreshold*60);
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
        :local stringMsg ">- $($clients->"name"->$index) BHE 3OHbl '$idDev'";       # client is 'out of zone'
        [$Output $stringMsg];
        :set ($clients->"time"->$index) (-[$T2U]);                                  # time of set status 'out of zone'
        :set ($clients->"msg"->$index) false;                                       # message 'out of zone' is sent
      } else={                                                                      # when client is presented in bridge hosts ->
        :local stringMsg ">+ $($clients->"name"->$index) OKOJlO '$idDev'";          # client is 'near'
        [$Output $stringMsg];
        :set ($clients->"time"->$index) [$T2U];                                     # time of set status 'near'
        :set ($clients->"msg"->$index) true;                                        # message 'near' is sent
      }
    } else={                                                                        # when client is presented in base of clients ->
      :if ([len $hostMac]=0) do={                                                   # when client is not presented in bridge hosts ->
        :if (($clients->"time"->$index)>0) do={                                     # when client has status 'near' ->
          :if ((($clients->"time"->$index)+$timeThreshold)<[$T2U]) do={             # when status 'near' more threshold time ->
            :if (($clients->"msg"->$index)=true) do={                               # when message 'out of zone' was not sent ->
              :local stringMsg "-- $($clients->"name"->$index) BHE 3OHbl '$idDev' C $[$U2T ([$T2U]-$timeThreshold) "time"]";
              [$Output $stringMsg];                                                 # client is 'out of zone'
              :set ($clients->"msg"->$index) false;                                 # message 'out of zone' is sent
              :set ($clients->"time"->$index) (-[$T2U]);                            # time of set status 'out of zone'
            }
          }
        }
      } else={                                                                      # when client is presented in bridge hosts ->
        :if (($clients->"time"->$index)<0) do={                                     # when client has status 'out of zone' ->
          :if (($clients->"msg"->$index)=false) do={                                # when message 'near' was not sent ->
            :local stringMsg "++ $($clients->"name"->$index) OKOJlO '$idDev'";      # client is 'near'
            [$Output $stringMsg];
            :set ($clients->"msg"->$index) true;                                    # message 'near' is sent
            :set ($clients->"time"->$index) [$T2U];                                 # time of set status 'near'
          }
        }
      }
    }
  }
}
