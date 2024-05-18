#!/bin/sh

PARA=$1
CONFIG="config.xml"
main()
{
	GATELOG=`grep gatewayserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	ZONELOG=`grep zoneserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	LOGINLOG=`grep loginserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	MONITORLOG=`grep monitorserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	SDKLOG=`grep sdkserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	GMLOG=`grep gmserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	LBYLOG=`grep lobbyserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'`
	ALL=$LOGINLOG" "$GATELOG" "$ZONELOG" "$MONITORLOG" "$SDKLOG" "$GMLOG" "

	
	clear
	case $PARA in 
		zs)
		tail --follow=name --retry $ZONELOG --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		gw)
		tail --follow=name --retry $GATELOG --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		lo)
		tail --follow=name --retry $LOGINLOG  --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		mt)
		tail --follow=name --retry $MONITORLOG  --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		sdk)
		tail --follow=name --retry $SDKLOG  --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		gm)
		tail --follow=name --retry $GMLOG  --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		lb)
		tail --follow=name --retry $LBYLOG  --max-unchanged-stats=3 -n 40 -q |../tools/color
		;;
		*)
		#tail --follow=name --retry $ALL --max-unchanged-stats=3 -n 5 -q |grep "109[^0-9]"
		tail --follow=name --retry $ALL --max-unchanged-stats=3 -n 5 -q  |../tools/color
		;;
	esac
}
main
