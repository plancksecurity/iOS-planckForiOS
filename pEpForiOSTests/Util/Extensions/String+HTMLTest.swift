//
//  String+HTMLTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 17/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class String_HTMLTest: XCTestCase {

    func testIOS2430() {
        //the number of times img tag is expeccted to be found.
        let expectedresult = 42
        let result = htmlConvertImageLinksToImageMarkdownString(html: IOS2430, attachmentDelegate: nil)
    }
}

extension String_HTMLTest {
    var IOS2430: String {
        return """
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.=
w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> <html xmlns=3D"http://www.w3=
.org/1999/xhtml" xmlns:v=3D"urn:schemas-microsoft-com:vml" xmlns:o=3D"urn:s=
chemas-microsoft-com:office:office"> <head> <meta http-equiv=3D"Content-Typ=
e" content=3D"text/html; charset=3Dutf-8" /> <meta name=3D"format-detection=
" content=3D"address=3Dno"> <meta name=3D"viewport" content=3D"width=3Ddevi=
ce-width, initial-scale=3D1.0"> <title>Groupon</title> <style type=3D"text/=
css"> .ExternalClass *{line-height:100%}table{font-family:'Open Sans',Arial=
,sans-serif!important}table.helvetica{font-family:Helvetica,Arial,sans-seri=
f!important}table.ls_nav_font{font-family:Nunito,'Open Sans',Arial,sans-ser=
if!important}a,div,li,p,td{-webkit-text-size-adjust:none}img[class=3D"100"]=
{width:100%!important;min-width:100%!important;max-width:100%!important}.ap=
pleLinks a,.appleLinksBlack a{color:#333!important;text-decoration:none}.ap=
pleLinksGrey a{color:#75787b!important;text-decoration:none}.appleLinksGray=
a{color:#999!important;text-decoration:none}.appleLinksBlue a{color:#0093e=
a!important;text-decoration:none}.bg-color:hover{background-color:#367806!i=
mportant}@media only screen and (max-width:599px){div[class=3Dpattern-105],=
div[class=3Dpattern-117],div[class=3Dpattern-80]{position:relative!importan=
t;overflow:hidden!important;width:100%!important}div[class=3Dpattern-80]{he=
ight:80px!important}div[class=3Dpattern-105] img,div[class=3Dpattern-117] i=
mg,div[class=3Dpattern-80] img{position:absolute!important;top:0!important;=
left:50%!important;margin-left:-300px!important}div[class=3Dpattern-105]{he=
ight:105px!important}div[class=3Dpattern-117]{height:117px!important}}@medi=
a only screen and (max-width:580px){table[class=3Dinner_container],table[cl=
ass=3Douter_container]{border-spacing:0!important;border-collapse:collapse!=
important;margin:0 auto!important;padding:0!important}td[class=3DfloatLeft-=
name],td[class=3DfloatLeft-ship]{text-align:left!important;font-size:13px!i=
mportant;width:100%!important;float:left!important}table[class=3Dcontainer]=
{margin:0 auto!important;width:100%!important;min-width:100%!important}th[c=
lass=3Dcontainer]{margin:0 auto!important;width:100%!important;min-width:10=
0%!important;display:block!important}td[class=3Dcontainer]{width:100%!impor=
tant;min-width:100%!important;float:left!important;position:relative!import=
ant;padding:0!important}table[class=3Douter_container]{width:95%!important}=
table[class=3Dinner_container]{width:100%!important;min-width:100%!importan=
t}td[class=3Dinner_container]{width:100%!important;background-size:100%!imp=
ortant;margin:0 auto!important}td[class=3Dtd_featured]{width:100%!important=
;height:150px!important;background-size:100%!important;background-position:=
100% 50%;background-repeat:no-repeat;padding:0!important;margin:0 auto!impo=
rtant}td[class=3D"100"],td[class=3Dw100]{width:100%!important;min-width:100=
%!important;height:auto!important;float:left!important}td[class=3Dmobile-hd=
r-logo-center]{padding:25px 0 10px!important}img[class=3D"100"],img[class=
=3Dimg-mobile]{width:100%!important;min-width:100%!important;max-width:100%=
!important}[class=3Dcollapse-left],[class=3Dcollapse-right-rtl]{width:100%!=
important;float:left!important;position:relative!important;padding:20px 0!i=
mportant;border-bottom:1px solid #ccc!important}[class=3Dcollapse-left-rtl]=
,[class=3Dcollapse-right]{width:100%!important;float:left!important;positio=
n:relative!important;padding:20px 0!important;border:none!important}td[clas=
s=3Dcollapse-trxn]{width:100%!important;float:left!important;position:relat=
ive!important;padding:30px 0 0!important}td[class=3Dcontainer-33]{min-width=
:33%!important}td[class=3Dcol-4-mobile]{width:65%!important}td[class=3Dtax-=
mobile]{white-space:normal!important}td[class=3Dmobile-container-padding]{p=
adding:20px 10px!important}td[class=3Dclo-redesign-container-padding]{paddi=
ng:11px 37px 0!important}td[class=3Dmobile-container-padding-none]{padding:=
0!important}td.ga-mobile-pad{padding:20px 0 15px 10px!important}td[class=3D=
weekend-mobile-container-padding]{padding:0 10px 20px!important}td[class=3D=
mobile-container-nav-padding]{padding:10px 0!important}td[class=3Dmobile-co=
ntainer-category]{padding:10px!important}td[class=3DfloatLeft-ship]{border:=
0!important;padding:5px 0 15px!important;line-height:14px!important}td[clas=
s=3DfloatLeft-name]{border:0!important;padding:5px 0!important;line-height:=
14px!important;font-weight:700!important}td[class=3Dno-padding]{padding:0!i=
mportant}td[class=3Dno-border-no-padding]{padding:0!important;border:none!i=
mportant}.no-border{border:none!important}[class=3Ddisplay-off]{display:non=
e!important}td[class=3Dshipment-col-4-mobile]{width:50%!important}[class=3D=
container-white]{width:100%!important;background-color:#fff!important;paddi=
ng:0!important}[class=3DtextAlignCenter]{text-align:center!important}table[=
class=3Dbutton-width]{width:80px!important}td[class=3DviewButtonMobile]{pad=
ding:12px 10px!important}[class=3Dmobile-banner-nopad],[class=3Dmobile-bann=
er]{width:100%!important;max-height:none!important;height:auto!important;di=
splay:block!important;padding:0!important;color:#000!important;font-size:32=
px!important;line-height:24px!important}[class=3Dmobile-banner-img-bn],[cla=
ss=3Dmobile-banner-img-holiday],[class=3Dmobile-banner-img]{color:#000!impo=
rtant;font-size:12px!important;display:block!important;width:100%!important=
}[class=3Dmobile-banner-img]{max-height:none!important;height:auto!importan=
t;padding:0!important}[class=3Dmobile-banner-img-holiday]{max-height:none!i=
mportant;height:auto!important;padding:16px 0 0!important}[class=3Dmobile-b=
anner-img-bn]{height:100%!important;max-width:154px!important;max-height:10=
0%!important;padding:0!important}img[class=3D"2up-image-mobile-bn"],img[cla=
ss=3Dmobile-banner-img-bn-center],img[class=3Dmobile-banner-img-bn-right],i=
mg[class=3Dmobile-banner-img-bn]{width:100%!important;height:auto!important=
;display:block!important}[class=3Dmobile-banner-img-bn-center],[class=3Dmob=
ile-banner-img-bn-right]{width:100%!important;height:100%!important;max-wid=
th:154px!important;max-height:100%!important;padding:0!important;display:bl=
ock!important}[class=3D"2up-image-mobile-bn"]{width:100%!important;height:1=
00%!important;max-width:230px!important;max-height:100%!important;display:i=
nline!important;font-size:0!important}[class=3Dmobile-banner-img-pad],[clas=
s=3Dmobile-banner-img-padding]{color:#000!important;font-size:12px!importan=
t;max-height:none!important;display:block!important;height:auto!important;w=
idth:100%!important}[class=3Dmobile-banner-img-padding]{padding:14px 0 0!im=
portant}[class=3Dmobile-banner-img-pad]{padding:0 0 10px!important}[class=
=3D"2up-image-mobile"]{width:100%!important;max-height:none!important;heigh=
t:auto!important;display:block!important;float:left!important}[class=3Dhead=
ing_style]{-webkit-text-size-adjust:none!important;font-size:13px!important=
;font-style:normal!important;font-variant:normal!important;font-weight:400!=
important;font-family:Arial,Verdana,sans-serif!important;color:#cdf5ff!impo=
rtant;line-height:18px!important}[class=3Dfont-13],td[class=3Dmobile-font]{=
font-size:13px!important}span[class=3DnameFont],td[class=3DheroNameFont],td=
[class=3DnameFont]{font-size:18px!important;line-height:22px!important}td[c=
lass=3DthemeFont]{font-size:30px!important;line-height:34px!important}a[cla=
ss=3DheroNameFont]{text-decoration:none!important;font-size:18px!important;=
line-height:22px!important}[class=3Dfont-10-trxnl],[class=3Dfont-10]{font-s=
ize:10px!important;line-height:16px!important}[class=3Dfont-10-trxnl]{paddi=
ng:16px 0 0!important}[class=3Dfont-12]{font-size:12px!important}[class=3Df=
ont-13-padding]{font-size:13px!important;padding:0!important}[class=3Dfont-=
16]{font-size:16px!important}[class=3Dfont-18]{font-size:18px!important}[cl=
ass=3Dfont-24]{font-size:24px!important}img[class=3Dglive-deal-image]{width=
:80%!important;height:auto!important;display:block;margin:0 auto;padding:0}=
[class=3Duniversal-padding]{padding:31px 14px 28.5px!important}[class=3Duni=
versal-padding-trxnl]{padding:24px 24px 32px!important}[class=3Dapp-logo]{w=
idth:29px!important}td[class=3Dapp-text]{padding:7px 0 0 5px!important}img[=
class=3Dinstagram-logo]{width:22px!important}img[class=3Dfacebook-logo]{wid=
th:9.5px!important}img[class=3Dtwitter-logo]{width:27px!important}td[class=
=3Dinstagram-logo]{max-width:22px!important;padding:0 40px 0 0!important}td=
[class=3Dfacebook-logo]{max-width:9.5px!important;padding:0 40.5px 0 0!impo=
rtant}td[class=3Dtwitter-logo]{max-width:27px!important}div[class=3Dgmailfi=
x]{display:none;display:none!important}[class=3DpostcardButtonPadding]{padd=
ing:10px 0 0 1px!important}[class=3Done_hundred]{width:100%!important;min-w=
idth:100%!important;max-width:100%!important}[class=3Dno-padding]{padding:0=
!important}.display_block,[class=3Ddisplay_block]{display:block!important}.=
border-top{border-left:none!important;border-top:1px solid #000;border-coll=
apse:collapse;display:block}} *[class].viewButton {-moz-border-radius: 4px =
4px 4px 4px; -webkit-border-radius: 4px 4px 4px 4px; -khtml-border-radius: =
4px 4px 4px 4px; border-radius: 4px 4px 4px 4px;} </style> <!--[if !mso]><!=
--> <style> @media only screen and (max-width: 580px) { .app-store-mobile {=
width: 113px !important; height: 37px !important; } .google-play-mobile { =
width: 129px !important; height: 37px !important; } td[class=3D"collapse-le=
ft-postcard"]{ width: 100% !important; float: left !important; position: re=
lative !important; padding: 20px 0 20px 0 !important; } table[class=3D"seo-=
button-width"]{ width: 158px !important; } table[class=3D"container_border"=
]{ width: 100% !important; padding: 0 0 0 0 !important; } *[class=3D"margin=
_zero_auto"]{ margin: 0 auto !important; display: block !important; } *[cla=
ss=3D"text_pad"]{ padding:7px 0 0 0 !important; } *[class=3D"display_table"=
]{ display: block !important; width:100% !important; } } </style> <!--<![en=
dif]--> <link href=3D'https://fonts.googleapis.com/css?family=3DOpen+Sans:1=
00,200,400,300,500,600,700,800' rel=3D'stylesheet' type=3D'text/css' /> <li=
nk href=3D"https://fonts.googleapis.com/css?family=3DNunito:700" rel=3D"sty=
lesheet"> </head> <body style=3D"margin:0 !important; padding:0 !important;=
background: #f2f2f2 !important;"> <div class=3D"gmailfix" style=3D"white-s=
pace:nowrap; font:15px courier; line-height:0;"> &nbsp; &nbsp; &nbsp; &nbsp=
; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nb=
sp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &=
nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </div> <img src =3D "https://www.groupon.=
es/analytic/trackintl.gif?p=3D1&utm_domain=3Dgmail.com&utm_campaign=3D1dd3a=
ca7-c991-4973-95de-b6edb2434cf1_0_20200915&deals=3D577f1743-7dc4-4cf5-8e5f-=
f3d6056bf815,09277604-a8cf-4fb5-8c5d-1483c2116ffc,0624f0b4-515d-4745-b79e-1=
2aa826608d5,d7fbbb28-0f80-4fa2-9274-3321734b938b,e32bcc97-975c-43ed-85c3-4a=
f8d016ada5,2337992c-1886-4532-a894-d5fe42b5f413,aa1f1938-f90c-4fbc-8e58-3f5=
b21523a91,68393298-d3e4-47d6-9a02-5c5bc6301f4f,2531753f-6d82-460e-9c48-f67b=
81682560,dedb73b2-eeae-4812-81bc-d4d89fc993f4,f32ccec4-bc98-4509-883b-fb554=
2545d94,66480276-8e9c-4186-8bc8-e3553c37bbe1,d64aa636-a9fb-443d-9ac9-eee5a8=
784fb8,ba56a831-058c-43ee-be6c-b94aa5873b85,7b87205c-40c0-44f7-b37a-caa2f2e=
9b6d4,fa8bfb33-fd66-46f1-a146-c03a87be675f,dac82d52-5a03-4509-a575-067a84c1=
ad4f,40a51e8d-c814-42a3-b91a-63b4b227b0af,2c1d9820-2f75-49a7-9d62-ad5693c36=
4cc,b8345c38-6607-4409-b3bb-7bc249cd01c2&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54=
-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demai=
l&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcel=
ona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dtracking_pixel_uuid&d=3Dnone" =
height=3D"1" width=3D"1" style=3D"display: none !important;" /> <span style=
=3D"color: #ffffff; font-size: 0px;" height=3D"0"> <span class=3D"previewCo=
py" style=3D"color: #ffffff; font-size: 0px !important; height: 0px; displa=
y: none;" height=3D"0"> </span> </span> <table cellpadding=3D"0" cellspacin=
g=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans=
', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; text-a=
lign: left; width: 100%; background: #f2f2f2;" align=3D"center"> <tr> <td a=
lign=3D"center" style=3D"padding: 20px 0 15px 0;" class=3D"mobile-hdr-logo-=
center"><a href=3D"https://www.groupon.es?nlp=3D&CID=3DES&uu=3Dc56d325e-ec5=
4-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Dema=
il&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarce=
lona&date=3D20201509&sender=3Drm&s=3Dheader&c=3Dimage&d=3Dgroupon" style=3D=
"font-size: 34px; color: #333333; font-weight: normal; color:#ffffff; font-=
weight: 700;" target=3D"_blank"><img src=3D"http://s3.grouponcdn.com/email/=
images/prom_night/global_images/hdr-logo-GRPN-green.png" style=3D"display: =
block; border: none; width: 151px;" width=3D"151" alt=3D"GROUPON&reg;" titl=
e=3D"GROUPON&reg;" /></a></td> </tr> </table> <table cellpadding=3D"0" cell=
spacing=3D"0" style=3D"width: 100%; background: #f2f2f2;" align=3D"center">=
<tr> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"width: 670px; bac=
kground: #ffffff;" bgcolor=3D"#ffffff" align=3D"center" class=3D"container"=
> <tr> <td align=3D"center"> <table cellpadding=3D"0" cellspacing=3D"0" sty=
le=3D"width: 600px; min-width:600px; background: #ffffff;" bgcolor=3D"#ffff=
ff" align=3D"center" class=3D"container"> <tr> <td align=3D"center" style=
=3D"padding: 0 0 40px 0;" class=3D"mobile-container-padding"> <table cellpa=
dding=3D"0" cellspacing=3D"0" width=3D"600" align=3D"center" class=3D"conta=
iner"> <tr> <td align=3D"center" style=3D"padding:10px 0 10px 0;" ><a href=
=3D"https://www.groupon.es/browse/?context=3Dlocal&p=3D1&nlp=3D&CID=3DES&uu=
=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&u=
tm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_d=
ivision=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dmsg&c=3D273875&d=3Dgene=
ric_message-page&utm_campaign=3Dcrmsg_273875" target=3D"_blank" style=3D"te=
xt-decoration:none;"> <table cellpadding=3D"0" cellspacing=3D"0" width=3D"6=
00" align=3D"center" class=3D"container"> <tr> <td align=3D"center" > <tabl=
e cellpadding=3D"0" cellspacing=3D"0" width=3D"600" align=3D"center" class=
=3D"container"> <tr> <td align=3D"center"> <table cellpadding=3D"0" cellspa=
cing=3D"0" width=3D"100%" align=3D"center"> <tr> <td class=3D"mobile-banner=
-img" align=3D"center" valign=3D"middle" style=3D"padding:0px; display:none=
; font-size:0; max-height:0; line-height:0; mso-hide: all;"><a href=3D"http=
s://www.groupon.es/browse/?context=3Dlocal&p=3D1&nlp=3D&CID=3DES&uu=3Dc56d3=
25e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_mediu=
m=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=
=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dmsg&c=3D273875&d=3Dgeneric_mes=
sage-page&utm_campaign=3Dcrmsg_273875" target=3D"_blank"> <img class=3D"mob=
ile-banner-img" src=3D"https://img.grouponcdn.com/message-service/4Cz6GRJff=
eLVp5j9NGHDGL1aNw4x/4C-460x140" style=3D"padding:0px; display:none; max-hei=
ght:0; mso-hide: all;" border=3D"0" /> </a></td> </tr> <tr> <td class=3D"di=
splay-off" align=3D"center" valign=3D"middle" height=3D"58" width=3D"600" s=
tyle=3D"-webkit-text-size-adjust:none;font-size:13px;font-style:normal;font=
-variant:normal;font-weight:normal;font-family:Arial, Verdana, sans-serif; =
color:#cdf5ff; line-height:18px; width:600px;"><a href=3D"https://www.group=
on.es/browse/?context=3Dlocal&p=3D1&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea=
-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=
=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&d=
ate=3D20201509&sender=3Drm&s=3Dmsg&c=3D273875&d=3Dgeneric_message-page&utm_=
campaign=3Dcrmsg_273875" target=3D"_blank" style=3D"color:#cdf5ff; text-dec=
oration:none;"> <img class=3D"100" src=3D"https://img.grouponcdn.com/messag=
e-service/4HThosLjS29EYD3Gt3LPeL7M55bP/4H-600x140" style=3D"display: block;=
border: none; width:600px;" width=3D"600" /> </a></td> </tr> </table> </td=
> </tr> </table> </td> </tr> </table> </a></td> </tr> </table> <table cellp=
adding=3D"0" cellspacing=3D"0" style=3D"width: 600px; min-width:600px;" wid=
th=3D"600" align=3D"center" class=3D"container"> <tr> <td align=3D"center" =
style=3D"width:600px; min-width:600px;" width=3D"600" class=3D"container"> =
<table cellpadding=3D"0" cellspacing=3D"0" style =3D "border: 0 none; borde=
r-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color=
:#000000; font-weight: normal; text-align: left; width: 600px;" align=3D "c=
enter" class=3D"container"> <tr> <td align=3D"left" valign=3D"top" class=3D=
"mobile-container-padding-additional"> <table cellpadding=3D"0" cellspacing=
=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans'=
, Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; text-al=
ign: left; width:290px; background: #ffffff;" class=3D"container" align=3D'=
left'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'=
left' class=3D"split-card-no-border"> <table cellpadding=3D"0" cellspacing=
=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans'=
, Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; text-al=
ign: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"de=
al_link" href=3D"https://www.groupon.es/deals/eco-belly-1?p=3D3&nlp=3D&CID=
=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchan=
dising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_2020=
0915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&=
d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-decoration:no=
ne;"><img src=3D"https://img.grouponcdn.com/deal/2SbkJeyrpeku5MiPmGTqc9uG8o=
MB/2S-1500x900/v1/t300x182.jpg" style=3D"display: block; border: none; widt=
h: 290px;" width=3D"290" alt=3D"Sesi=C3=B3n de ecograf=C3=ADa 5D" title=3D"=
Sesi=C3=B3n de ecograf=C3=ADa 5D" class=3D"100"></a></td> </tr> <tr> <td al=
ign=3D"left" style=3D"font-size: 16px; color: #333333; font-weight: normal;=
padding: 5px 0 0 0;"colspan=3D"2">Sesi=C3=B3n de ecograf=C3=ADa 5D</td> </=
tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999; font-=
weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> Eco Belly </td> </tr> <t=
r> <td align=3D"left" style=3D"font-size: 13px; color: #999999; font-weight=
: normal;" colspan=3D"2">Cerdanyola del Valles</td> </tr> <td align=3D"left=
" style=3D"padding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.gr=
ouponcdn.com/email/images/icons/review_stars/4-5@3x.png" style=3D"display: =
block; border: none; display:inline; width: 69px;" width=3D"69" class=3D"" =
/></span><span style=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-=
off">&nbsp;(174)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" =
align=3D"left"> <span style=3D"font-size: 16px; text-decoration: line-throu=
gh; color:#848484; font-weight: normal; color:#848484;"> 45,00&nbsp;=E2=82=
=AC </span> <span style=3D"font-size: 18px; color: #53A318; font-weight: bo=
ld;"> Desde 34,99&nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D=
"padding: 5px 0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"=
border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Ari=
al, sans-serif; color:#000000; font-weight: normal; text-align: left;"> <tr=
> <td style=3D"color: #ffffff; background: #53A318; font-size: 12px; text-a=
lign: center; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a hr=
ef=3D"https://www.groupon.es/deals/eco-belly-1?p=3D3&nlp=3D&CID=3DES&uu=3Dc=
56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_m=
edium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_divis=
ion=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-pa=
ge" target=3D"_blank" style=3D"text-decoration: none; color: #ffffff; displ=
ay: inline-block; border-radius: 3px; -webkit-border-radius: 3px; -moz-bord=
er-radius: 3px; background-color: #53A318; border-top: 12px solid #53A318; =
border-bottom: 12px solid #53A318; border-right: 18px solid #53A318; border=
-left: 18px solid #53A318; white-space:nowrap;"> Descubre </a></td> </tr> <=
/table> </td> </tr> </table> </td> </tr> </table> <table cellpadding=3D"0" =
cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: =
'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: norm=
al; text-align: left; width:290px; background: #ffffff;" class=3D"container=
" align=3D'right'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; =
;" align=3D'right' class=3D"split-card-no-border"> <table cellpadding=3D"0"=
cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family:=
'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: nor=
mal; text-align: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"=
><a id=3D"deal_link" href=3D"https://www.groupon.es/deals/cmip-eixample?p=
=3D4&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_s=
ource=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6ed=
b2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3D=
body&c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; tex=
t-decoration:none;"><img src=3D"https://img.grouponcdn.com/deal/nWuYz8oURFE=
2ux6BoKhkrx/16536910-700x420/v1/t300x182.jpg" style=3D"display: block; bord=
er: none; width: 290px;" width=3D"290" alt=3D"Certificado m=C3=A9dico psico=
t=C3=A9cnico" title=3D"Certificado m=C3=A9dico psicot=C3=A9cnico" class=3D"=
100"></a></td> </tr> <tr> <td align=3D"left" style=3D"font-size: 16px; colo=
r: #333333; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">Certific=
ado m=C3=A9dico psicot=C3=A9cnico</td> </tr> <tr> <td align=3D"left" style=
=3D"font-size: 13px; color: #999999; font-weight: normal; padding: 5px 0 0 =
0;"colspan=3D"2"> Cmip Eixample </td> </tr> <tr> <td align=3D"left" style=
=3D"font-size: 13px; color: #999999; font-weight: normal;" colspan=3D"2">Ba=
rcelona</td> </tr> <td align=3D"left" style=3D"padding: 4px 0 0 0; " class=
=3D""> <span><img src=3D"http://s3.grouponcdn.com/email/images/icons/review=
_stars/4-5@3x.png" style=3D"display: block; border: none; display:inline; w=
idth: 69px;" width=3D"69" class=3D"" /></span><span style=3D"font-size: 13p=
x; color: #a5a8ab;" class=3D"display-off">&nbsp;(119)</span><br /> </td> <t=
r> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span style=3D"font-si=
ze: 16px; text-decoration: line-through; color:#848484; font-weight: normal=
; color:#848484;"> 45,00&nbsp;=E2=82=AC </span> <span style=3D"font-size: 1=
8px; color: #53A318; font-weight: bold;"> 24,95&nbsp;=E2=82=AC </span> </td=
> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <table cellpadding=3D"=
0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-famil=
y: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: n=
ormal; text-align: left;"> <tr> <td style=3D"color: #ffffff; background: #5=
3A318; font-size: 12px; text-align: center; font-family: 'Helvetica',Arial,=
sans-serif,'Open Sans';"><a href=3D"https://www.groupon.es/deals/cmip-eixam=
ple?p=3D4&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&=
utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de=
-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm=
&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" style=3D"text-decorat=
ion: none; color: #ffffff; display: inline-block; border-radius: 3px; -webk=
it-border-radius: 3px; -moz-border-radius: 3px; background-color: #53A318; =
border-top: 12px solid #53A318; border-bottom: 12px solid #53A318; border-r=
ight: 18px solid #53A318; border-left: 18px solid #53A318; white-space:nowr=
ap;"> Descubre </a></td> </tr> </table> </td> </tr> </table> </td> </tr> </=
table> </td> </tr> <tr> <td align=3D"left" valign=3D"top" class=3D"mobile-c=
ontainer-padding-additional"> <table cellpadding=3D"0" cellspacing=3D"0" st=
yle=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helveti=
ca, Arial, sans-serif; color:#000000; font-weight: normal; text-align: left=
; width:290px; background: #ffffff;" class=3D"container" align=3D'left'> <t=
r> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'left' cla=
ss=3D"split-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" sty=
le=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetic=
a, Arial, sans-serif; color:#000000; font-weight: normal; text-align: left;=
width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" h=
ref=3D"https://www.groupon.es/deals/solmania-9?p=3D5&nlp=3D&CID=3DES&uu=3Dc=
56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_m=
edium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_divis=
ion=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-pag=
e" target=3D"_blank" style=3D"color:#0185C6; text-decoration:none;"><img sr=
c=3D"https://img.grouponcdn.com/deal/2aNwoDGdhF22X1s3UWyT1RGv83YY/2a-700x41=
9/v1/t300x182.jpg" style=3D"display: block; border: none; width: 290px;" wi=
dth=3D"290" alt=3D"Bono de bronceado con rayos UVA" title=3D"Bono de bronce=
ado con rayos UVA" class=3D"100"></a></td> </tr> <tr> <td align=3D"left" st=
yle=3D"font-size: 16px; color: #333333; font-weight: normal; padding: 5px 0=
0 0;"colspan=3D"2">Bono de bronceado con rayos UVA</td> </tr> <tr> <td ali=
gn=3D"left" style=3D"font-size: 13px; color: #999999; font-weight: normal; =
padding: 5px 0 0 0;"colspan=3D"2"> Solman=C3=ADa </td> </tr> <tr> <td align=
=3D"left" style=3D"font-size: 13px; color: #999999; font-weight: normal;" c=
olspan=3D"2">Varias localizaciones</td> </tr> <td align=3D"left" style=3D"p=
adding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com=
/email/images/icons/review_stars/4-5@3x.png" style=3D"display: block; borde=
r: none; display:inline; width: 69px;" width=3D"69" class=3D"" /></span><sp=
an style=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(=
340)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"lef=
t"> <span style=3D"font-size: 16px; text-decoration: line-through; color:#8=
48484; font-weight: normal; color:#848484;"> 36,00&nbsp;=E2=82=AC </span> <=
span style=3D"font-size: 18px; color: #53A318; font-weight: bold;"> Desde 1=
7,95&nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px=
0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 non=
e; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-seri=
f; color:#000000; font-weight: normal; text-align: left;"> <tr> <td style=
=3D"color: #ffffff; background: #53A318; font-size: 12px; text-align: cente=
r; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https=
://www.groupon.es/deals/solmania-9?p=3D5&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54=
-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demai=
l&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcel=
ona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=
=3D"_blank" style=3D"text-decoration: none; color: #ffffff; display: inline=
-block; border-radius: 3px; -webkit-border-radius: 3px; -moz-border-radius:=
3px; background-color: #53A318; border-top: 12px solid #53A318; border-bot=
tom: 12px solid #53A318; border-right: 18px solid #53A318; border-left: 18p=
x solid #53A318; white-space:nowrap;"> Descubre </a></td> </tr> </table> </=
td> </tr> </table> </td> </tr> </table> <table cellpadding=3D"0" cellspacin=
g=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans=
', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; text-a=
lign: left; width:290px; background: #ffffff;" class=3D"container" align=3D=
'right'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=
=3D'right' class=3D"split-card-no-border"> <table cellpadding=3D"0" cellspa=
cing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open S=
ans', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; tex=
t-align: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=
=3D"deal_link" href=3D"https://www.groupon.es/deals/electrogym-8?p=3D6&nlp=
=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3D=
merchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1=
_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=
=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-deco=
ration:none;"><img src=3D"https://img.grouponcdn.com/deal/3SH3fNESkrzNuVKzg=
TUV53otqoaA/3S-2048x1229/v1/t300x182.jpg" style=3D"display: block; border: =
none; width: 290px;" width=3D"290" alt=3D"Electroestimulaci=C3=B3n con entr=
enador " title=3D"Electroestimulaci=C3=B3n con entrenador " class=3D"100"><=
/a></td> </tr> <tr> <td align=3D"left" style=3D"font-size: 16px; color: #33=
3333; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">Electroestimul=
aci=C3=B3n con entrenador </td> </tr> <tr> <td align=3D"left" style=3D"font=
-size: 13px; color: #999999; font-weight: normal; padding: 5px 0 0 0;"colsp=
an=3D"2"> Electrogym </td> </tr> <td align=3D"left" style=3D"padding: 4px 0=
0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com/email/images=
/icons/review_stars/4-5@3x.png" style=3D"display: block; border: none; disp=
lay:inline; width: 69px;" width=3D"69" class=3D"" /></span><span style=3D"f=
ont-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(18)</span><br=
/> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span styl=
e=3D"font-size: 16px; text-decoration: line-through; color:#848484; font-we=
ight: normal; color:#848484;"> 210,00&nbsp;=E2=82=AC </span> <span style=3D=
"font-size: 18px; color: #53A318; font-weight: bold;"> Desde 69,95&nbsp;=E2=
=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <ta=
ble cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spa=
cing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000=
000; font-weight: normal; text-align: left;"> <tr> <td style=3D"color: #fff=
fff; background: #53A318; font-size: 12px; text-align: center; font-family:=
'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.=
es/deals/electrogym-8?p=3D6&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-02=
42ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3a=
ca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20=
201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" sty=
le=3D"text-decoration: none; color: #ffffff; display: inline-block; border-=
radius: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; backgroun=
d-color: #53A318; border-top: 12px solid #53A318; border-bottom: 12px solid=
#53A318; border-right: 18px solid #53A318; border-left: 18px solid #53A318=
; white-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> </tab=
le> </td> </tr> </table> </td> </tr> <tr> <td align=3D"left" valign=3D"top"=
class=3D"mobile-container-padding-additional"> <table cellpadding=3D"0" ce=
llspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'O=
pen Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal=
; text-align: left; width:290px; background: #ffffff;" class=3D"container" =
align=3D'left'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" =
align=3D'left' class=3D"split-card-no-border"> <table cellpadding=3D"0" cel=
lspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Op=
en Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal;=
text-align: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a =
id=3D"deal_link" href=3D"https://www.groupon.es/deals/ecox-hospitalet?p=3D7=
&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_sourc=
e=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb243=
4cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody=
&c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-de=
coration:none;"><img src=3D"https://img.grouponcdn.com/deal/4LFJsmAfJjMg54R=
ZdtkZCYhNomKV/4L-2048x1229/v1/t300x182.jpg" style=3D"display: block; border=
: none; width: 290px;" width=3D"290" alt=3D"Ecograf=C3=ADa 5D" title=3D"Eco=
graf=C3=ADa 5D" class=3D"100"></a></td> </tr> <tr> <td align=3D"left" style=
=3D"font-size: 16px; color: #333333; font-weight: normal; padding: 5px 0 0 =
0;"colspan=3D"2">Ecograf=C3=ADa 5D</td> </tr> <tr> <td align=3D"left" style=
=3D"font-size: 13px; color: #999999; font-weight: normal; padding: 5px 0 0 =
0;"colspan=3D"2"> Ecox Hospitalet </td> </tr> <tr> <td align=3D"left" style=
=3D"font-size: 13px; color: #999999; font-weight: normal;" colspan=3D"2">Ho=
spitalet De Llobregat</td> </tr> <td align=3D"left" style=3D"padding: 4px 0=
0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com/email/images=
/icons/review_stars/4-5@3x.png" style=3D"display: block; border: none; disp=
lay:inline; width: 69px;" width=3D"69" class=3D"" /></span><span style=3D"f=
ont-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(33)</span><br=
/> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span styl=
e=3D"font-size: 16px; text-decoration: line-through; color:#848484; font-we=
ight: normal; color:#848484;"> 105,00&nbsp;=E2=82=AC </span> <span style=3D=
"font-size: 18px; color: #53A318; font-weight: bold;"> Desde 59,99&nbsp;=E2=
=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <ta=
ble cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spa=
cing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000=
000; font-weight: normal; text-align: left;"> <tr> <td style=3D"color: #fff=
fff; background: #53A318; font-size: 12px; text-align: center; font-family:=
'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.=
es/deals/ecox-hospitalet?p=3D7&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a=
-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1d=
d3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=
=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank=
" style=3D"text-decoration: none; color: #ffffff; display: inline-block; bo=
rder-radius: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; back=
ground-color: #53A318; border-top: 12px solid #53A318; border-bottom: 12px =
solid #53A318; border-right: 18px solid #53A318; border-left: 18px solid #5=
3A318; white-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> =
</table> </td> </tr> </table> <table cellpadding=3D"0" cellspacing=3D"0" st=
yle=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helveti=
ca, Arial, sans-serif; color:#000000; font-weight: normal; text-align: left=
; width:290px; background: #ffffff;" class=3D"container" align=3D'right'> <=
tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'right' c=
lass=3D"split-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" s=
tyle=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvet=
ica, Arial, sans-serif; color:#000000; font-weight: normal; text-align: lef=
t; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link"=
href=3D"https://www.groupon.es/deals/centro-medico-katarsia-1?p=3D8&nlp=3D=
&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmer=
chandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_=
20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dim=
age&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-decoratio=
n:none;"><img src=3D"https://img.grouponcdn.com/iam/4RKh6vSNz57HM2zichh8uWQ=
tYwrJ/4R-2048x1229/v1/t300x182.jpg" style=3D"display: block; border: none; =
width: 290px;" width=3D"290" alt=3D"Infiltraci=C3=B3n=C2=A0de =C3=A1cido hi=
alur=C3=B3nico" title=3D"Infiltraci=C3=B3n=C2=A0de =C3=A1cido hialur=C3=B3n=
ico" class=3D"100"></a></td> </tr> <tr> <td align=3D"left" style=3D"font-si=
ze: 16px; color: #333333; font-weight: normal; padding: 5px 0 0 0;"colspan=
=3D"2">Infiltraci=C3=B3n=C2=A0de =C3=A1cido hialur=C3=B3nico</td> </tr> <tr=
> <td align=3D"left" style=3D"font-size: 13px; color: #999999; font-weight:=
normal; padding: 5px 0 0 0;"colspan=3D"2"> Centro M=C3=A9dico Katarsia </t=
d> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999; =
font-weight: normal;" colspan=3D"2">Barcelona</td> </tr> <td align=3D"left"=
style=3D"padding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.gro=
uponcdn.com/email/images/icons/review_stars/4-5@3x.png" style=3D"display: b=
lock; border: none; display:inline; width: 69px;" width=3D"69" class=3D"" /=
></span><span style=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-o=
ff">&nbsp;(3)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" ali=
gn=3D"left"> <span style=3D"font-size: 16px; text-decoration: line-through;=
color:#848484; font-weight: normal; color:#848484;"> 198,00&nbsp;=E2=82=AC=
</span> <span style=3D"font-size: 18px; color: #53A318; font-weight: bold;=
"> Desde 119,00&nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"p=
adding: 5px 0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bo=
rder: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial=
, sans-serif; color:#000000; font-weight: normal; text-align: left;"> <tr> =
<td style=3D"color: #ffffff; background: #53A318; font-size: 12px; text-ali=
gn: center; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=
=3D"https://www.groupon.es/deals/centro-medico-katarsia-1?p=3D8&nlp=3D&CID=
=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchan=
dising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_2020=
0915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton=
&d=3Ddeal-page" target=3D"_blank" style=3D"text-decoration: none; color: #f=
fffff; display: inline-block; border-radius: 3px; -webkit-border-radius: 3p=
x; -moz-border-radius: 3px; background-color: #53A318; border-top: 12px sol=
id #53A318; border-bottom: 12px solid #53A318; border-right: 18px solid #53=
A318; border-left: 18px solid #53A318; white-space:nowrap;"> Descubre </a><=
/td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </tr> <=
tr> <td align=3D"left" valign=3D"top" class=3D"mobile-container-padding-add=
itional"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 non=
e; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-seri=
f; color:#000000; font-weight: normal; text-align: left; width:290px; backg=
round: #ffffff;" class=3D"container" align=3D'left'> <tr> <td valign=3D"top=
" style=3D"padding: 10px 0 0 0; ; ;" align=3D'left' class=3D"split-card-no-=
border"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none=
; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif=
; color:#000000; font-weight: normal; text-align: left; width: 100%;"> <tr>=
<td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"https://www.g=
roupon.es/deals/ortopedia-gironell-17?p=3D9&nlp=3D&CID=3DES&uu=3Dc56d325e-e=
c54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3De=
mail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbar=
celona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-page" target=
=3D"_blank" style=3D"color:#0185C6; text-decoration:none;"><img src=3D"http=
s://img.grouponcdn.com/iam/dZYnexxLGU6KXPTissS5/ZB-2048x1229/v1/t300x182.jp=
g" style=3D"display: block; border: none; width: 290px;" width=3D"290" alt=
=3D"Estudio de la pisada y plantillas" title=3D"Estudio de la pisada y plan=
tillas" class=3D"100"></a></td> </tr> <tr> <td align=3D"left" style=3D"font=
-size: 16px; color: #333333; font-weight: normal; padding: 5px 0 0 0;"colsp=
an=3D"2">Estudio de la pisada y plantillas</td> </tr> <tr> <td align=3D"lef=
t" style=3D"font-size: 13px; color: #999999; font-weight: normal; padding: =
5px 0 0 0;"colspan=3D"2"> Ortopedia Gironell </td> </tr> <tr> <td align=3D"=
left" style=3D"font-size: 13px; color: #999999; font-weight: normal;" colsp=
an=3D"2">Varias localizaciones</td> </tr> <td align=3D"left" style=3D"paddi=
ng: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com/ema=
il/images/icons/review_stars/4@3x.png" style=3D"display: block; border: non=
e; display:inline; width: 69px;" width=3D"69" class=3D"" /></span><span sty=
le=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(54)</s=
pan><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <sp=
an style=3D"font-size: 16px; text-decoration: line-through; color:#848484; =
font-weight: normal; color:#848484;"> 176,00&nbsp;=E2=82=AC </span> <span s=
tyle=3D"font-size: 18px; color: #53A318; font-weight: bold;"> Desde 49,90&n=
bsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0=
;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; bor=
der-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; col=
or:#000000; font-weight: normal; text-align: left;"> <tr> <td style=3D"colo=
r: #ffffff; background: #53A318; font-size: 12px; text-align: center; font-=
family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.g=
roupon.es/deals/ortopedia-gironell-17?p=3D9&nlp=3D&CID=3DES&uu=3Dc56d325e-e=
c54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3De=
mail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbar=
celona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" targe=
t=3D"_blank" style=3D"text-decoration: none; color: #ffffff; display: inlin=
e-block; border-radius: 3px; -webkit-border-radius: 3px; -moz-border-radius=
: 3px; background-color: #53A318; border-top: 12px solid #53A318; border-bo=
ttom: 12px solid #53A318; border-right: 18px solid #53A318; border-left: 18=
px solid #53A318; white-space:nowrap;"> Descubre </a></td> </tr> </table> <=
/td> </tr> </table> </td> </tr> </table> <table cellpadding=3D"0" cellspaci=
ng=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open San=
s', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; text-=
align: left; width:290px; background: #ffffff;" class=3D"container" align=
=3D'right'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" alig=
n=3D'right' class=3D"split-card-no-border"> <table cellpadding=3D"0" cellsp=
acing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open =
Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; te=
xt-align: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=
=3D"deal_link" href=3D"https://www.groupon.es/deals/centre-medic-sentits?p=
=3D10&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_=
source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6e=
db2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=
=3Dbody&c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; =
text-decoration:none;"><img src=3D"https://img.grouponcdn.com/iam/ZVXpVt1AW=
KK3SjgyiA7VTFJMAKh/ZV-2048x1229/v1/t300x182.jpg" style=3D"display: block; b=
order: none; width: 290px;" width=3D"290" alt=3D"Certificado m=C3=A9dico ps=
icot=C3=A9cnico" title=3D"Certificado m=C3=A9dico psicot=C3=A9cnico" class=
=3D"100"></a></td> </tr> <tr> <td align=3D"left" style=3D"font-size: 16px; =
color: #333333; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">Cert=
ificado m=C3=A9dico psicot=C3=A9cnico</td> </tr> <tr> <td align=3D"left" st=
yle=3D"font-size: 13px; color: #999999; font-weight: normal; padding: 5px 0=
0 0;"colspan=3D"2"> Centre Medic Sentits </td> </tr> <td align=3D"left" st=
yle=3D"padding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.groupo=
ncdn.com/email/images/icons/review_stars/4-5@3x.png" style=3D"display: bloc=
k; border: none; display:inline; width: 69px;" width=3D"69" class=3D"" /></=
span><span style=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-off"=
>&nbsp;(376)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" alig=
n=3D"left"> <span style=3D"font-size: 16px; text-decoration: line-through; =
color:#848484; font-weight: normal; color:#848484;"> 47,00&nbsp;=E2=82=AC <=
/span> <span style=3D"font-size: 18px; color: #53A318; font-weight: bold;">=
24,95&nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5=
px 0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 n=
one; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-se=
rif; color:#000000; font-weight: normal; text-align: left;"> <tr> <td style=
=3D"color: #ffffff; background: #53A318; font-size: 12px; text-align: cente=
r; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https=
://www.groupon.es/deals/centre-medic-sentits?p=3D10&nlp=3D&CID=3DES&uu=3Dc5=
6d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_me=
dium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_divisi=
on=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-pag=
e" target=3D"_blank" style=3D"text-decoration: none; color: #ffffff; displa=
y: inline-block; border-radius: 3px; -webkit-border-radius: 3px; -moz-borde=
r-radius: 3px; background-color: #53A318; border-top: 12px solid #53A318; b=
order-bottom: 12px solid #53A318; border-right: 18px solid #53A318; border-=
left: 18px solid #53A318; white-space:nowrap;"> Descubre </a></td> </tr> </=
table> </td> </tr> </table> </td> </tr> </table> </td> </tr> <tr> <td align=
=3D"left" valign=3D"top" class=3D"mobile-container-padding-additional"> <ta=
ble cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spa=
cing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000=
000; font-weight: normal; text-align: left; width:290px; background: #fffff=
f;" class=3D"container" align=3D'left'> <tr> <td valign=3D"top" style=3D"pa=
dding: 10px 0 0 0; ; ;" align=3D'left' class=3D"split-card-no-border"> <tab=
le cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spac=
ing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#0000=
00; font-weight: normal; text-align: left; width: 100%;"> <tr> <td valign=
=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"https://www.groupon.es/d=
eals/aurora-clinique?p=3D11&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-02=
42ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3a=
ca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20=
201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-page" target=3D"_blank" styl=
e=3D"color:#0185C6; text-decoration:none;"><img src=3D"https://img.grouponc=
dn.com/deal/ikUpQFX7hBagNSvCgsA6AQXiXky/ik-711x425/v1/t300x182.jpg" style=
=3D"display: block; border: none; width: 290px;" width=3D"290" alt=3D"Infil=
traci=C3=B3n de =C3=A1cido hialur=C3=B3nico" title=3D"Infiltraci=C3=B3n de =
=C3=A1cido hialur=C3=B3nico" class=3D"100"></a></td> </tr> <tr> <td align=
=3D"left" style=3D"font-size: 16px; color: #333333; font-weight: normal; pa=
dding: 5px 0 0 0;"colspan=3D"2">Infiltraci=C3=B3n de =C3=A1cido hialur=C3=
=B3nico</td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color:=
#999999; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> Cl=C3=ADn=
ica Mont Blanc </td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px=
; color: #999999; font-weight: normal;" colspan=3D"2">Barcelona</td> </tr> =
<tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span style=3D"font-=
size: 16px; text-decoration: line-through; color:#848484; font-weight: norm=
al; color:#848484;"> 250,00&nbsp;=E2=82=AC </span> <span style=3D"font-size=
: 18px; color: #53A318; font-weight: bold;"> Desde 119,00&nbsp;=E2=82=AC </=
span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <table cellp=
adding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; =
font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font=
-weight: normal; text-align: left;"> <tr> <td style=3D"color: #ffffff; back=
ground: #53A318; font-size: 12px; text-align: center; font-family: 'Helveti=
ca',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.es/deals/=
aurora-clinique?p=3D11&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac1=
20002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c=
991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D2020150=
9&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" style=3D=
"text-decoration: none; color: #ffffff; display: inline-block; border-radiu=
s: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; background-col=
or: #53A318; border-top: 12px solid #53A318; border-bottom: 12px solid #53A=
318; border-right: 18px solid #53A318; border-left: 18px solid #53A318; whi=
te-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> </table> <=
/td> </tr> </table> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bor=
der: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial,=
sans-serif; color:#000000; font-weight: normal; text-align: left; width:29=
0px; background: #ffffff;" class=3D"container" align=3D'right'> <tr> <td va=
lign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'right' class=3D"sp=
lit-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bo=
rder: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial=
, sans-serif; color:#000000; font-weight: normal; text-align: left; width: =
100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"h=
ttps://www.groupon.es/deals/quiropractic-studio?p=3D12&nlp=3D&CID=3DES&uu=
=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&u=
tm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_d=
ivision=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal=
-page" target=3D"_blank" style=3D"color:#0185C6; text-decoration:none;"><im=
g src=3D"https://img.grouponcdn.com/iam/3FSdpbnuihsFG5WL5fE4LH3t8Fwb/3F-204=
8x1229/v1/t300x182.jpg" style=3D"display: block; border: none; width: 290px=
;" width=3D"290" alt=3D"Tratamiento quiropr=C3=A1ctico" title=3D"Tratamient=
o quiropr=C3=A1ctico" class=3D"100"></a></td> </tr> <tr> <td align=3D"left"=
style=3D"font-size: 16px; color: #333333; font-weight: normal; padding: 5p=
x 0 0 0;"colspan=3D"2">Tratamiento quiropr=C3=A1ctico</td> </tr> <tr> <td a=
lign=3D"left" style=3D"font-size: 13px; color: #999999; font-weight: normal=
; padding: 5px 0 0 0;"colspan=3D"2"> Quiropractic Studio </td> </tr> <tr> <=
td align=3D"left" style=3D"font-size: 13px; color: #999999; font-weight: no=
rmal;" colspan=3D"2">Barcelona</td> </tr> <td align=3D"left" style=3D"paddi=
ng: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com/ema=
il/images/icons/review_stars/4-5@3x.png" style=3D"display: block; border: n=
one; display:inline; width: 69px;" width=3D"69" class=3D"" /></span><span s=
tyle=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(18)<=
/span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <=
span style=3D"font-size: 16px; text-decoration: line-through; color:#848484=
; font-weight: normal; color:#848484;"> 60,00&nbsp;=E2=82=AC </span> <span =
style=3D"font-size: 18px; color: #53A318; font-weight: bold;"> Desde 19,99&=
nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 =
0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; bo=
rder-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; co=
lor:#000000; font-weight: normal; text-align: left;"> <tr> <td style=3D"col=
or: #ffffff; background: #53A318; font-size: 12px; text-align: center; font=
-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.=
groupon.es/deals/quiropractic-studio?p=3D12&nlp=3D&CID=3DES&uu=3Dc56d325e-e=
c54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3De=
mail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbar=
celona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" targe=
t=3D"_blank" style=3D"text-decoration: none; color: #ffffff; display: inlin=
e-block; border-radius: 3px; -webkit-border-radius: 3px; -moz-border-radius=
: 3px; background-color: #53A318; border-top: 12px solid #53A318; border-bo=
ttom: 12px solid #53A318; border-right: 18px solid #53A318; border-left: 18=
px solid #53A318; white-space:nowrap;"> Descubre </a></td> </tr> </table> <=
/td> </tr> </table> </td> </tr> </table> </td> </tr> <tr> <td align=3D"left=
" valign=3D"top" class=3D"mobile-container-padding-additional"> <table cell=
padding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0;=
font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; fon=
t-weight: normal; text-align: left; width:290px; background: #ffffff;" clas=
s=3D"container" align=3D'left'> <tr> <td valign=3D"top" style=3D"padding: 1=
0px 0 0 0; ; ;" align=3D'left' class=3D"split-card-no-border"> <table cellp=
adding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; =
font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font=
-weight: normal; text-align: left; width: 100%;"> <tr> <td valign=3D"top" c=
olspan=3D"2"><a id=3D"deal_link" href=3D"https://www.groupon.es/deals/fit-c=
uerpazo?p=3D13&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=
=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973=
-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=
=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0=
185C6; text-decoration:none;"><img src=3D"https://img.grouponcdn.com/deal/3=
QFHGT5Cy8De2KkiX4BCGX17kL6k/3Q-1868x1121/v1/t300x182.jpg" style=3D"display:=
block; border: none; width: 290px;" width=3D"290" alt=3D"Plan de dieta y e=
jercicio" title=3D"Plan de dieta y ejercicio" class=3D"100"></a></td> </tr>=
<tr> <td align=3D"left" style=3D"font-size: 16px; color: #333333; font-wei=
ght: normal; padding: 5px 0 0 0;"colspan=3D"2">Plan de dieta y ejercicio</t=
d> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999; =
font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> Fit Cuerpazo </td> =
</tr> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span style=3D=
"font-size: 16px; text-decoration: line-through; color:#848484; font-weight=
: normal; color:#848484;"> 60,00&nbsp;=E2=82=AC </span> <span style=3D"font=
-size: 18px; color: #53A318; font-weight: bold;"> Desde 4,99&nbsp;=E2=82=AC=
</span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <table ce=
llpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: =
0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; f=
ont-weight: normal; text-align: left;"> <tr> <td style=3D"color: #ffffff; b=
ackground: #53A318; font-size: 12px; text-align: center; font-family: 'Helv=
etica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.es/dea=
ls/fit-cuerpazo?p=3D13&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac1=
20002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c=
991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D2020150=
9&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" style=3D=
"text-decoration: none; color: #ffffff; display: inline-block; border-radiu=
s: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; background-col=
or: #53A318; border-top: 12px solid #53A318; border-bottom: 12px solid #53A=
318; border-right: 18px solid #53A318; border-left: 18px solid #53A318; whi=
te-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> </table> <=
/td> </tr> </table> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bor=
der: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial,=
sans-serif; color:#000000; font-weight: normal; text-align: left; width:29=
0px; background: #ffffff;" class=3D"container" align=3D'right'> <tr> <td va=
lign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'right' class=3D"sp=
lit-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bo=
rder: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial=
, sans-serif; color:#000000; font-weight: normal; text-align: left; width: =
100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"h=
ttps://www.groupon.es/deals/axis-3?p=3D14&nlp=3D&CID=3DES&uu=3Dc56d325e-ec5=
4-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Dema=
il&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarce=
lona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-page" target=
=3D"_blank" style=3D"color:#0185C6; text-decoration:none;"><img src=3D"http=
s://img.grouponcdn.com/iam/4VtfiyRB1UMcLz5XmvkJky7toj81/4V-2048x1229/v1/t30=
0x182.jpg" style=3D"display: block; border: none; width: 290px;" width=3D"2=
90" alt=3D"Certificado m=C3=A9dico psicot=C3=A9cnico" title=3D"Certificado =
m=C3=A9dico psicot=C3=A9cnico" class=3D"100"></a></td> </tr> <tr> <td align=
=3D"left" style=3D"font-size: 16px; color: #333333; font-weight: normal; pa=
dding: 5px 0 0 0;"colspan=3D"2">Certificado m=C3=A9dico psicot=C3=A9cnico</=
td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999;=
font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> Axis </td> </tr> <=
tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999; font-weigh=
t: normal;" colspan=3D"2">AXIS</td> </tr> <td align=3D"left" style=3D"paddi=
ng: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com/ema=
il/images/icons/review_stars/4-5@3x.png" style=3D"display: block; border: n=
one; display:inline; width: 69px;" width=3D"69" class=3D"" /></span><span s=
tyle=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(219)=
</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> =
<span style=3D"font-size: 16px; text-decoration: line-through; color:#84848=
4; font-weight: normal; color:#848484;"> 46,00&nbsp;=E2=82=AC </span> <span=
style=3D"font-size: 18px; color: #53A318; font-weight: bold;"> 24,95&nbsp;=
=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> =
<table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-=
spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#=
000000; font-weight: normal; text-align: left;"> <tr> <td style=3D"color: #=
ffffff; background: #53A318; font-size: 12px; text-align: center; font-fami=
ly: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.group=
on.es/deals/axis-3?p=3D14&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242=
ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca=
7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D2020=
1509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" style=
=3D"text-decoration: none; color: #ffffff; display: inline-block; border-ra=
dius: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; background-=
color: #53A318; border-top: 12px solid #53A318; border-bottom: 12px solid #=
53A318; border-right: 18px solid #53A318; border-left: 18px solid #53A318; =
white-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> </table=
> </td> </tr> </table> </td> </tr> <tr> <td align=3D"left" valign=3D"top" c=
lass=3D"mobile-container-padding-additional"> <table cellpadding=3D"0" cell=
spacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Ope=
n Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; =
text-align: left; width:290px; background: #ffffff;" class=3D"container" al=
ign=3D'left'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" al=
ign=3D'left' class=3D"split-card-no-border"> <table cellpadding=3D"0" cells=
pacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open=
Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: normal; t=
ext-align: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=
=3D"deal_link" href=3D"https://www.groupon.es/deals/cipsa-28?p=3D15&nlp=3D&=
CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerc=
handising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_2=
0200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dima=
ge&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-decoration=
:none;"><img src=3D"https://img.grouponcdn.com/iam/hVbbM66jn5XkeLRcB29S/SH-=
2048x1228/v1/t300x182.jpg" style=3D"display: block; border: none; width: 29=
0px;" width=3D"290" alt=3D"Infiltraci=C3=B3n de =C3=A1cido hialur=C3=B3nico=
" title=3D"Infiltraci=C3=B3n de =C3=A1cido hialur=C3=B3nico" class=3D"100">=
</a></td> </tr> <tr> <td align=3D"left" style=3D"font-size: 16px; color: #3=
33333; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">Infiltraci=C3=
=B3n de =C3=A1cido hialur=C3=B3nico</td> </tr> <tr> <td align=3D"left" styl=
e=3D"font-size: 13px; color: #999999; font-weight: normal; padding: 5px 0 0=
0;"colspan=3D"2"> Cl=C3=ADnica Cipsalut </td> </tr> <tr> <td align=3D"left=
" style=3D"font-size: 13px; color: #999999; font-weight: normal;" colspan=
=3D"2">Barcelona</td> </tr> <td align=3D"left" style=3D"padding: 4px 0 0 0;=
" class=3D""> <span><img src=3D"http://s3.grouponcdn.com/email/images/icon=
s/review_stars/4@3x.png" style=3D"display: block; border: none; display:inl=
ine; width: 69px;" width=3D"69" class=3D"" /></span><span style=3D"font-siz=
e: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(209)</span><br /> </=
td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span style=3D"f=
ont-size: 16px; text-decoration: line-through; color:#848484; font-weight: =
normal; color:#848484;"> 325,00&nbsp;=E2=82=AC </span> <span style=3D"font-=
size: 18px; color: #53A318; font-weight: bold;"> Desde 119,00&nbsp;=E2=82=
=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <table=
cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacin=
g: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000=
; font-weight: normal; text-align: left;"> <tr> <td style=3D"color: #ffffff=
; background: #53A318; font-size: 12px; text-align: center; font-family: 'H=
elvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.es/=
deals/cipsa-28?p=3D15&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac12=
0002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c9=
91-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509=
&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" style=3D"=
text-decoration: none; color: #ffffff; display: inline-block; border-radius=
: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; background-colo=
r: #53A318; border-top: 12px solid #53A318; border-bottom: 12px solid #53A3=
18; border-right: 18px solid #53A318; border-left: 18px solid #53A318; whit=
e-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> </table> </=
td> </tr> </table> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bord=
er: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, =
sans-serif; color:#000000; font-weight: normal; text-align: left; width:290=
px; background: #ffffff;" class=3D"container" align=3D'right'> <tr> <td val=
ign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'right' class=3D"spl=
it-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bor=
der: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial,=
sans-serif; color:#000000; font-weight: normal; text-align: left; width: 1=
00%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"ht=
tps://www.groupon.es/deals/0-complejos-9?p=3D16&nlp=3D&CID=3DES&uu=3Dc56d32=
5e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=
=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=
=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-page" =
target=3D"_blank" style=3D"color:#0185C6; text-decoration:none;"><img src=
=3D"https://img.grouponcdn.com/deal/GKekVoGG6uHaSS5JQwxMpQDkWX4/GK-2048x122=
9/v1/t300x182.jpg" style=3D"display: block; border: none; width: 290px;" wi=
dth=3D"290" alt=3D"Mesoterapia capilar con plasma" title=3D"Mesoterapia cap=
ilar con plasma" class=3D"100"></a></td> </tr> <tr> <td align=3D"left" styl=
e=3D"font-size: 16px; color: #333333; font-weight: normal; padding: 5px 0 0=
0;"colspan=3D"2">Mesoterapia capilar con plasma</td> </tr> <tr> <td align=
=3D"left" style=3D"font-size: 13px; color: #999999; font-weight: normal; pa=
dding: 5px 0 0 0;"colspan=3D"2"> 0 Complejos </td> </tr> <tr> <td align=3D"=
left" style=3D"font-size: 13px; color: #999999; font-weight: normal;" colsp=
an=3D"2">Varias localizaciones</td> </tr> <tr> <td style=3D"padding: 3px 0 =
0 0;" align=3D"left"> <span style=3D"font-size: 16px; text-decoration: line=
-through; color:#848484; font-weight: normal; color:#848484;"> 190,00&nbsp;=
=E2=82=AC </span> <span style=3D"font-size: 18px; color: #53A318; font-weig=
ht: bold;"> Desde 89,99&nbsp;=E2=82=AC </span> </td> <td align=3D"right" st=
yle=3D"padding: 5px 0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" sty=
le=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetic=
a, Arial, sans-serif; color:#000000; font-weight: normal; text-align: left;=
"> <tr> <td style=3D"color: #ffffff; background: #53A318; font-size: 12px; =
text-align: center; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"=
><a href=3D"https://www.groupon.es/deals/0-complejos-9?p=3D16&nlp=3D&CID=3D=
ES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandis=
ing&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_2020091=
5&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=
=3Ddeal-page" target=3D"_blank" style=3D"text-decoration: none; color: #fff=
fff; display: inline-block; border-radius: 3px; -webkit-border-radius: 3px;=
-moz-border-radius: 3px; background-color: #53A318; border-top: 12px solid=
#53A318; border-bottom: 12px solid #53A318; border-right: 18px solid #53A3=
18; border-left: 18px solid #53A318; white-space:nowrap;"> Descubre </a></t=
d> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </tr> <tr=
> <td align=3D"left" valign=3D"top" class=3D"mobile-container-padding-addit=
ional"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none;=
border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif;=
color:#000000; font-weight: normal; text-align: left; width:290px; backgro=
und: #ffffff;" class=3D"container" align=3D'left'> <tr> <td valign=3D"top" =
style=3D"padding: 10px 0 0 0; ; ;" align=3D'left' class=3D"split-card-no-bo=
rder"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; =
border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; =
color:#000000; font-weight: normal; text-align: left; width: 100%;"> <tr> <=
td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"https://www.gro=
upon.es/deals/ruben-poveda-fisioterapia-acupuntura-y-medicina-tradicional-c=
hina?p=3D17&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D=
0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95=
de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3D=
rm&s=3Dbody&c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185=
C6; text-decoration:none;"><img src=3D"https://img.grouponcdn.com/bynder/4X=
65Wrc31yo4ub3xr23WoQUDS6g/4X-2048x1229/v1/t300x182.jpg" style=3D"display: b=
lock; border: none; width: 290px;" width=3D"290" alt=3D"1 o 3 sesiones de f=
isioterapia" title=3D"1 o 3 sesiones de fisioterapia" class=3D"100"></a></t=
d> </tr> <tr> <td align=3D"left" style=3D"font-size: 16px; color: #333333; =
font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">1 o 3 sesiones de fi=
sioterapia</td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; col=
or: #999999; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> Fisiot=
erapia, Acupuntura y... </td> </tr> <tr> <td align=3D"left" style=3D"font-s=
ize: 13px; color: #999999; font-weight: normal;" colspan=3D"2">Varias local=
izaciones</td> </tr> <td align=3D"left" style=3D"padding: 4px 0 0 0; " clas=
s=3D""> <span><img src=3D"http://s3.grouponcdn.com/email/images/icons/revie=
w_stars/4@3x.png" style=3D"display: block; border: none; display:inline; wi=
dth: 69px;" width=3D"69" class=3D"" /></span><span style=3D"font-size: 13px=
; color: #a5a8ab;" class=3D"display-off">&nbsp;(28)</span><br /> </td> <tr>=
<td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span style=3D"font-size=
: 16px; text-decoration: line-through; color:#848484; font-weight: normal; =
color:#848484;"> 40,00&nbsp;=E2=82=AC </span> <span style=3D"font-size: 18p=
x; color: #53A318; font-weight: bold;"> Desde 19,99&nbsp;=E2=82=AC </span> =
</td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <table cellpadding=
=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-f=
amily: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weigh=
t: normal; text-align: left;"> <tr> <td style=3D"color: #ffffff; background=
: #53A318; font-size: 12px; text-align: center; font-family: 'Helvetica',Ar=
ial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.es/deals/ruben-=
poveda-fisioterapia-acupuntura-y-medicina-tradicional-china?p=3D17&nlp=3D&C=
ID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerch=
andising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20=
200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutt=
on&d=3Ddeal-page" target=3D"_blank" style=3D"text-decoration: none; color: =
#ffffff; display: inline-block; border-radius: 3px; -webkit-border-radius: =
3px; -moz-border-radius: 3px; background-color: #53A318; border-top: 12px s=
olid #53A318; border-bottom: 12px solid #53A318; border-right: 18px solid #=
53A318; border-left: 18px solid #53A318; white-space:nowrap;"> Descubre </a=
></td> </tr> </table> </td> </tr> </table> </td> </tr> </table> <table cell=
padding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0;=
font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; fon=
t-weight: normal; text-align: left; width:290px; background: #ffffff;" clas=
s=3D"container" align=3D'right'> <tr> <td valign=3D"top" style=3D"padding: =
10px 0 0 0; ; ;" align=3D'right' class=3D"split-card-no-border"> <table cel=
lpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0=
; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; fo=
nt-weight: normal; text-align: left; width: 100%;"> <tr> <td valign=3D"top"=
colspan=3D"2"><a id=3D"deal_link" href=3D"https://www.groupon.es/deals/eco=
x-4d-prenatal-barcelona-4?p=3D18&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-87=
5a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D=
1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=
=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3Ddeal-page" target=3D"_blank"=
style=3D"color:#0185C6; text-decoration:none;"><img src=3D"https://img.gro=
uponcdn.com/deal/34WL8DUg3VefHFdRC4VmMMnmtmKf/34-700x420/v1/t300x182.jpg" s=
tyle=3D"display: block; border: none; width: 290px;" width=3D"290" alt=3D"E=
cograf=C3=ADa 5D" title=3D"Ecograf=C3=ADa 5D" class=3D"100"></a></td> </tr>=
<tr> <td align=3D"left" style=3D"font-size: 16px; color: #333333; font-wei=
ght: normal; padding: 5px 0 0 0;"colspan=3D"2">Ecograf=C3=ADa 5D</td> </tr>=
<tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999; font-wei=
ght: normal; padding: 5px 0 0 0;"colspan=3D"2"> Ecox 4D Prenatal Barcelona =
</td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #99999=
9; font-weight: normal;" colspan=3D"2">Barcelona</td> </tr> <td align=3D"le=
ft" style=3D"padding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.=
grouponcdn.com/email/images/icons/review_stars/4-5@3x.png" style=3D"display=
: block; border: none; display:inline; width: 69px;" width=3D"69" class=3D"=
" /></span><span style=3D"font-size: 13px; color: #a5a8ab;" class=3D"displa=
y-off">&nbsp;(212)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;=
" align=3D"left"> <span style=3D"font-size: 16px; text-decoration: line-thr=
ough; color:#848484; font-weight: normal; color:#848484;"> 145,00&nbsp;=E2=
=82=AC </span> <span style=3D"font-size: 18px; color: #53A318; font-weight:=
bold;"> 49,99&nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"pa=
dding: 5px 0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bor=
der: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial,=
sans-serif; color:#000000; font-weight: normal; text-align: left;"> <tr> <=
td style=3D"color: #ffffff; background: #53A318; font-size: 12px; text-alig=
n: center; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=
=3D"https://www.groupon.es/deals/ecox-4d-prenatal-barcelona-4?p=3D18&nlp=3D=
&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmer=
chandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_=
20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbu=
tton&d=3Ddeal-page" target=3D"_blank" style=3D"text-decoration: none; color=
: #ffffff; display: inline-block; border-radius: 3px; -webkit-border-radius=
: 3px; -moz-border-radius: 3px; background-color: #53A318; border-top: 12px=
solid #53A318; border-bottom: 12px solid #53A318; border-right: 18px solid=
#53A318; border-left: 18px solid #53A318; white-space:nowrap;"> Descubre <=
/a></td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </t=
r> <tr> <td align=3D"left" valign=3D"top" class=3D"mobile-container-padding=
-additional"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0=
none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-=
serif; color:#000000; font-weight: normal; text-align: left; width:290px; b=
ackground: #ffffff;" class=3D"container" align=3D'left'> <tr> <td valign=3D=
"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'left' class=3D"split-card=
-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 =
none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-s=
erif; color:#000000; font-weight: normal; text-align: left; width: 100%;"> =
<tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"https://w=
ww.groupon.es/deals/clinicas-laser-fusion-barcelona-4?p=3D19&nlp=3D&CID=3DE=
S&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandisi=
ng&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915=
&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&d=3D=
deal-page" target=3D"_blank" style=3D"color:#0185C6; text-decoration:none;"=
><img src=3D"https://img.grouponcdn.com/deal/2oS9wyh7kGXe1pmZVSrMzPxLbNr3/2=
o-2048x1229/v1/t300x182.jpg" style=3D"display: block; border: none; width: =
290px;" width=3D"290" alt=3D"Tratamiento reductor" title=3D"Tratamiento red=
uctor" class=3D"100"></a></td> </tr> <tr> <td align=3D"left" style=3D"font-=
size: 16px; color: #333333; font-weight: normal; padding: 5px 0 0 0;"colspa=
n=3D"2">Tratamiento reductor</td> </tr> <tr> <td align=3D"left" style=3D"fo=
nt-size: 13px; color: #999999; font-weight: normal; padding: 5px 0 0 0;"col=
span=3D"2"> C=C3=ADnicas L=C3=A1ser Fusi=C3=B3n Barcelona </td> </tr> <tr> =
<td align=3D"left" style=3D"font-size: 13px; color: #999999; font-weight: n=
ormal;" colspan=3D"2">Cl=C3=ADnicas L=C3=A1ser Fusi=C3=B3n</td> </tr> <tr> =
<td style=3D"padding: 3px 0 0 0;" align=3D"left"> <span style=3D"font-size:=
16px; text-decoration: line-through; color:#848484; font-weight: normal; c=
olor:#848484;"> 160,00&nbsp;=E2=82=AC </span> <span style=3D"font-size: 18p=
x; color: #53A318; font-weight: bold;"> Desde 49,95&nbsp;=E2=82=AC </span> =
</td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> <table cellpadding=
=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-f=
amily: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weigh=
t: normal; text-align: left;"> <tr> <td style=3D"color: #ffffff; background=
: #53A318; font-size: 12px; text-align: center; font-family: 'Helvetica',Ar=
ial,sans-serif,'Open Sans';"><a href=3D"https://www.groupon.es/deals/clinic=
as-laser-fusion-barcelona-4?p=3D19&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-=
875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=
=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&d=
ate=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_bl=
ank" style=3D"text-decoration: none; color: #ffffff; display: inline-block;=
border-radius: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; b=
ackground-color: #53A318; border-top: 12px solid #53A318; border-bottom: 12=
px solid #53A318; border-right: 18px solid #53A318; border-left: 18px solid=
#53A318; white-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </t=
r> </table> </td> </tr> </table> <table cellpadding=3D"0" cellspacing=3D"0"=
style=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helv=
etica, Arial, sans-serif; color:#000000; font-weight: normal; text-align: l=
eft; width:290px; background: #ffffff;" class=3D"container" align=3D'right'=
> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'right=
' class=3D"split-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0=
" style=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Hel=
vetica, Arial, sans-serif; color:#000000; font-weight: normal; text-align: =
left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_li=
nk" href=3D"https://www.groupon.es/deals/ecox-4d-prenatal-barcelona?p=3D20&=
nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=
=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434=
cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&=
c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-dec=
oration:none;"><img src=3D"https://img.grouponcdn.com/deal/wuewZrELExTo2S62=
nu8MdMtzpon/wu-2048x1229/v1/t300x182.jpg" style=3D"display: block; border: =
none; width: 290px;" width=3D"290" alt=3D"Ecograf=C3=ADa 4D del beb=C3=A9" =
title=3D"Ecograf=C3=ADa 4D del beb=C3=A9" class=3D"100"></a></td> </tr> <tr=
> <td align=3D"left" style=3D"font-size: 16px; color: #333333; font-weight:=
normal; padding: 5px 0 0 0;"colspan=3D"2">Ecograf=C3=ADa 4D del beb=C3=A9<=
/td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #999999=
; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> Ecox 4D Prenatal =
</td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px; color: #99999=
9; font-weight: normal;" colspan=3D"2">Barcelona</td> </tr> <td align=3D"le=
ft" style=3D"padding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.=
grouponcdn.com/email/images/icons/review_stars/4-5@3x.png" style=3D"display=
: block; border: none; display:inline; width: 69px;" width=3D"69" class=3D"=
" /></span><span style=3D"font-size: 13px; color: #a5a8ab;" class=3D"displa=
y-off">&nbsp;(206)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;=
" align=3D"left"> <span style=3D"font-size: 16px; text-decoration: line-thr=
ough; color:#848484; font-weight: normal; color:#848484;"> 79,00&nbsp;=E2=
=82=AC </span> <span style=3D"font-size: 18px; color: #53A318; font-weight:=
bold;"> Desde 39,00&nbsp;=E2=82=AC </span> </td> <td align=3D"right" style=
=3D"padding: 5px 0 0 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=
=3D"border: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica,=
Arial, sans-serif; color:#000000; font-weight: normal; text-align: left;">=
<tr> <td style=3D"color: #ffffff; background: #53A318; font-size: 12px; te=
xt-align: center; font-family: 'Helvetica',Arial,sans-serif,'Open Sans';"><=
a href=3D"https://www.groupon.es/deals/ecox-4d-prenatal-barcelona?p=3D20&nl=
p=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=
=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434=
cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&=
c=3Dbutton&d=3Ddeal-page" target=3D"_blank" style=3D"text-decoration: none;=
color: #ffffff; display: inline-block; border-radius: 3px; -webkit-border-=
radius: 3px; -moz-border-radius: 3px; background-color: #53A318; border-top=
: 12px solid #53A318; border-bottom: 12px solid #53A318; border-right: 18px=
solid #53A318; border-left: 18px solid #53A318; white-space:nowrap;"> Desc=
ubre </a></td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </t=
d> </tr> <tr> <td align=3D"left" valign=3D"top" class=3D"mobile-container-p=
adding-additional"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bor=
der: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial,=
sans-serif; color:#000000; font-weight: normal; text-align: left; width:29=
0px; background: #ffffff;" class=3D"container" align=3D'left'> <tr> <td val=
ign=3D"top" style=3D"padding: 10px 0 0 0; ; ;" align=3D'left' class=3D"spli=
t-card-no-border"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"bord=
er: 0 none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, =
sans-serif; color:#000000; font-weight: normal; text-align: left; width: 10=
0%;"> <tr> <td valign=3D"top" colspan=3D"2"><a id=3D"deal_link" href=3D"htt=
ps://www.groupon.es/deals/centre-medic-sagrada-familia-1?p=3D21&nlp=3D&CID=
=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchan=
dising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_2020=
0915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dimage&=
d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-decoration:no=
ne;"><img src=3D"https://img.grouponcdn.com/bynder/iyDywuJswaSxZJENMgzqyMh3=
hGD/iy-2048x1229/v1/t300x182.jpg" style=3D"display: block; border: none; wi=
dth: 290px;" width=3D"290" alt=3D"Certificado m=C3=A9dico psicot=C3=A9cnico=
" title=3D"Certificado m=C3=A9dico psicot=C3=A9cnico" class=3D"100"></a></t=
d> </tr> <tr> <td align=3D"left" style=3D"font-size: 16px; color: #333333; =
font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">Certificado m=C3=A9d=
ico psicot=C3=A9cnico</td> </tr> <tr> <td align=3D"left" style=3D"font-size=
: 13px; color: #999999; font-weight: normal; padding: 5px 0 0 0;"colspan=3D=
"2"> Centre M=C3=A9dic Sagrada Fam=C3=ADlia </td> </tr> <tr> <td align=3D"l=
eft" style=3D"font-size: 13px; color: #999999; font-weight: normal;" colspa=
n=3D"2">Centre M=C3=A9dic Sagrada</td> </tr> <td align=3D"left" style=3D"pa=
dding: 4px 0 0 0; " class=3D""> <span><img src=3D"http://s3.grouponcdn.com/=
email/images/icons/review_stars/4-5@3x.png" style=3D"display: block; border=
: none; display:inline; width: 69px;" width=3D"69" class=3D"" /></span><spa=
n style=3D"font-size: 13px; color: #a5a8ab;" class=3D"display-off">&nbsp;(1=
67)</span><br /> </td> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left=
"> <span style=3D"font-size: 16px; text-decoration: line-through; color:#84=
8484; font-weight: normal; color:#848484;"> 50,00&nbsp;=E2=82=AC </span> <s=
pan style=3D"font-size: 18px; color: #53A318; font-weight: bold;"> 24,95&nb=
sp;=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;=
"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; bord=
er-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; colo=
r:#000000; font-weight: normal; text-align: left;"> <tr> <td style=3D"color=
: #ffffff; background: #53A318; font-size: 12px; text-align: center; font-f=
amily: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.gr=
oupon.es/deals/centre-medic-sagrada-familia-1?p=3D21&nlp=3D&CID=3DES&uu=3Dc=
56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_m=
edium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_divis=
ion=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-pa=
ge" target=3D"_blank" style=3D"text-decoration: none; color: #ffffff; displ=
ay: inline-block; border-radius: 3px; -webkit-border-radius: 3px; -moz-bord=
er-radius: 3px; background-color: #53A318; border-top: 12px solid #53A318; =
border-bottom: 12px solid #53A318; border-right: 18px solid #53A318; border=
-left: 18px solid #53A318; white-space:nowrap;"> Descubre </a></td> </tr> <=
/table> </td> </tr> </table> </td> </tr> </table> <table cellpadding=3D"0" =
cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family: =
'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: norm=
al; text-align: left; width:290px; background: #ffffff;" class=3D"container=
" align=3D'right'> <tr> <td valign=3D"top" style=3D"padding: 10px 0 0 0; ; =
;" align=3D'right' class=3D"split-card-no-border"> <table cellpadding=3D"0"=
cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; font-family:=
'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-weight: nor=
mal; text-align: left; width: 100%;"> <tr> <td valign=3D"top" colspan=3D"2"=
><a id=3D"deal_link" href=3D"https://www.groupon.es/deals/biomes-7?p=3D22&n=
lp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=
=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434=
cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&=
c=3Dimage&d=3Ddeal-page" target=3D"_blank" style=3D"color:#0185C6; text-dec=
oration:none;"><img src=3D"https://img.grouponcdn.com/deal/3oA7PQqm8M3f6Aws=
YtgDi4FFtVXm/3o-1507x905/v1/t300x182.jpg" style=3D"display: block; border: =
none; width: 290px;" width=3D"290" alt=3D"An=C3=A1lisis de la flora intesti=
nal" title=3D"An=C3=A1lisis de la flora intestinal" class=3D"100"></a></td>=
</tr> <tr> <td align=3D"left" style=3D"font-size: 16px; color: #333333; fo=
nt-weight: normal; padding: 5px 0 0 0;"colspan=3D"2">An=C3=A1lisis de la fl=
ora intestinal</td> </tr> <tr> <td align=3D"left" style=3D"font-size: 13px;=
color: #999999; font-weight: normal; padding: 5px 0 0 0;"colspan=3D"2"> BI=
OMES </td> </tr> <tr> <td style=3D"padding: 3px 0 0 0;" align=3D"left"> <sp=
an style=3D"font-size: 16px; text-decoration: line-through; color:#848484; =
font-weight: normal; color:#848484;"> 149,90&nbsp;=E2=82=AC </span> <span s=
tyle=3D"font-size: 18px; color: #53A318; font-weight: bold;"> 99,00&nbsp;=
=E2=82=AC </span> </td> <td align=3D"right" style=3D"padding: 5px 0 0 0;"> =
<table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-=
spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#=
000000; font-weight: normal; text-align: left;"> <tr> <td style=3D"color: #=
ffffff; background: #53A318; font-size: 12px; text-align: center; font-fami=
ly: 'Helvetica',Arial,sans-serif,'Open Sans';"><a href=3D"https://www.group=
on.es/deals/biomes-7?p=3D22&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-02=
42ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3a=
ca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20=
201509&sender=3Drm&s=3Dbody&c=3Dbutton&d=3Ddeal-page" target=3D"_blank" sty=
le=3D"text-decoration: none; color: #ffffff; display: inline-block; border-=
radius: 3px; -webkit-border-radius: 3px; -moz-border-radius: 3px; backgroun=
d-color: #53A318; border-top: 12px solid #53A318; border-bottom: 12px solid=
#53A318; border-right: 18px solid #53A318; border-left: 18px solid #53A318=
; white-space:nowrap;"> Descubre </a></td> </tr> </table> </td> </tr> </tab=
le> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> <table c=
ellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing:=
0; font-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; =
font-weight: normal; text-align: left; width: 100%; background-color: #ffff=
ff;" align=3D"center"> <tr> <td style=3D"padding: 0px; display:none; font-s=
ize:0; max-height:0; line-height:0; mso-hide: all;" class=3D"mobile-banner"=
><a href=3D"https://www.groupon.es/occasion/weather-ready?category=3Dbellez=
a&p=3D23&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&u=
tm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-=
b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&=
s=3Dbody&c=3Dbanner&d=3Ddynamic-banner-2" style=3D"color:#0185C6; text-deco=
ration:none;" target=3D"_blank"> <img src=3D"https://img.grouponcdn.com/spa=
rta/2qzQDUatHjq4bWjwLWJLNKipU6fV/2q-600x140" style=3D"padding:0px; display:=
none; font-size:0; max-height:0; line-height:0; mso-hide: all;" class=3D"mo=
bile-banner-img" alt=3D"Groupon" /></a> </td> </tr> </table> <table cellpad=
ding=3D"0" cellspacing=3D"0" style=3D"border: 0 none; border-spacing: 0; fo=
nt-family: 'Open Sans', Helvetica, Arial, sans-serif; color:#000000; font-w=
eight: normal; text-align: left; width: 100%; min-width:290px; background-c=
olor: #ffffff;" align=3D"center" class=3D"display-off"> <tr class=3D"displa=
y-off"> <td align=3D"center" style=3D"padding: 10px 0 10px 0; min-width:290=
px;" class=3D"display-off"><a href=3D"https://www.groupon.es/occasion/weath=
er-ready?category=3Dbelleza&p=3D23&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-=
875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=
=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&d=
ate=3D20201509&sender=3Drm&s=3Dbody&c=3Dbanner&d=3Ddynamic-banner-2" style=
=3D"color:#0185C6; text-decoration:none;" target=3D"_blank"> <img src=3D"ht=
tps://img.grouponcdn.com/sparta/2qzQDUatHjq4bWjwLWJLNKipU6fV/2q-600x140" st=
yle=3D"display: block; border: none; min-width:290px;" class=3D"display-off=
" alt=3D"Groupon" /></a> </td> </tr> </table> </td> </tr> </table> </td> </=
tr> </table> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"border: 0 =
none; border-spacing: 0; font-family: 'Open Sans', Helvetica, Arial, sans-s=
erif; color:#000000; font-weight: normal; text-align: left; width: 100%; ba=
ckground: #f2f2f2;" align=3D"center"> <tr> <td align=3D"center" style=3D"pa=
dding: 0;"> <table cellpadding=3D"0" cellspacing=3D"0" style=3D"width: 600p=
x; background: #f2f2f2;" align=3D"center" class=3D"container"> <tr> <td sty=
le=3D"font-size: 10px; color: #999999; line-height: 120%; padding: 20px 10p=
x 10px 10px;" align=3D"center" class=3D"mobile-font"> =C2=BFNecesitas ayuda=
? =C2=BFQuieres comentarnos algo? No dudes en <a href=3D"https://www.groupo=
n.es/customer_support?nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac12=
0002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c9=
91-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509=
&sender=3Drm&s=3Dfooter&c=3Dlink&d=3Dcontact" style=3D"color:#0185C6; text-=
decoration:none;" target=3D"_blank">contactar con nosotros</a>.<br /><br />=
El motivo de que haya recibido este email es porque martin.brude@gmail.com=
est=C3=A1 suscrito para la recepci=C3=B3n de correos electr=C3=B3nicos por=
parte de Groupon. Si no desea seguir recibiendo correos electr=C3=B3nicos =
de este tipo, puede darse de baja con tan solo hacer <a href=3D"https://www=
.groupon.es/subscription_center/unsubscribe/consumer/c56d325e-ec54-11ea-875=
a-0242ac120002?cmplistId=3Ddivision:barcelona&eh=3Df100988cd1b0ec92c76288ee=
b407c962746421b6a8fa33f1aaed876f9d7916a3&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54=
-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_medium=3Demai=
l&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=3Dbarcel=
ona&date=3D20201509&sender=3Drm&s=3Dfooter&c=3Dlink&d=3Dunsub" style=3D"col=
or:#0185C6; text-decoration:none;">click</a>. Si desea gestionar sus otras =
suscripciones, por favor haga click <a href=3D"https://www.groupon.es/subsc=
ription_center/c56d325e-ec54-11ea-875a-0242ac120002?cmplistId=3Ddivision:ba=
rcelona&eh=3Df100988cd1b0ec92c76288eeb407c962746421b6a8fa33f1aaed876f9d7916=
a3&nlp=3D&CID=3DES&uu=3Dc56d325e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_sou=
rce=3Dmerchandising&utm_medium=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2=
434cf1_0_20200915&t_division=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dfo=
oter&c=3Dlink&d=3Dsubscription_center" style=3D"color:#0185C6; text-decorat=
ion:none;">aqu=C3=AD</a>. <br /><br /> Enviado por Groupon International Li=
mited, Lower Ground Floor, Connaught House, 1 Burlington Road, Dublin 4, 21=
6410 Irlanda, NIF:501358. Si su cuenta a=C3=BAn no ha sido transferida a Gr=
oupon International Limited, este email ha sido enviado por Groupon Spain S=
.L.U. <br /><br /> </td> </tr> </table> <div id=3D"subjectLineCopy" style=
=3D"color: #f2f2f2; font-size: 0px !important; display: none;" height=3D"0"=
> Te ayudamos con un 20% EXTRA en tus buenos prop=C3=B3sitos de septiembre =
</div> </td> </tr> </table> </td> </tr> </table> <img src =3D "https://www.=
groupon.es/analytic/trackintl.gif?p=3D2&utm_domain=3Dgmail.com&utm_campaign=
=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&deals=3D577f1743-7dc4-4c=
f5-8e5f-f3d6056bf815,09277604-a8cf-4fb5-8c5d-1483c2116ffc,0624f0b4-515d-474=
5-b79e-12aa826608d5,d7fbbb28-0f80-4fa2-9274-3321734b938b,e32bcc97-975c-43ed=
-85c3-4af8d016ada5,2337992c-1886-4532-a894-d5fe42b5f413,aa1f1938-f90c-4fbc-=
8e58-3f5b21523a91,68393298-d3e4-47d6-9a02-5c5bc6301f4f,2531753f-6d82-460e-9=
c48-f67b81682560,dedb73b2-eeae-4812-81bc-d4d89fc993f4,f32ccec4-bc98-4509-88=
3b-fb5542545d94,66480276-8e9c-4186-8bc8-e3553c37bbe1,d64aa636-a9fb-443d-9ac=
9-eee5a8784fb8,ba56a831-058c-43ee-be6c-b94aa5873b85,7b87205c-40c0-44f7-b37a=
-caa2f2e9b6d4,fa8bfb33-fd66-46f1-a146-c03a87be675f,dac82d52-5a03-4509-a575-=
067a84c1ad4f,40a51e8d-c814-42a3-b91a-63b4b227b0af,2c1d9820-2f75-49a7-9d62-a=
d5693c364cc,b8345c38-6607-4409-b3bb-7bc249cd01c2&nlp=3D&CID=3DES&uu=3Dc56d3=
25e-ec54-11ea-875a-0242ac120002&tx=3D0&utm_source=3Dmerchandising&utm_mediu=
m=3Demail&sid=3D1dd3aca7-c991-4973-95de-b6edb2434cf1_0_20200915&t_division=
=3Dbarcelona&date=3D20201509&sender=3Drm&s=3Dbody&c=3Dtracking_pixel_uuid&d=
=3Dnone" height=3D"1" width=3D"1" style=3D"display: none !important;" /> </=
body> </html>
"""
    }
}
