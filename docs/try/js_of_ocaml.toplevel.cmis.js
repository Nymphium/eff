// Generated by js_of_ocaml 2.5+git-9881839
(function(joo_global_object_c_)
   {"use strict";
    function caml_fs_register_extern_a_(name_a_,content_b_)
     {if(joo_global_object_c_.caml_fs_register)
       joo_global_object_c_.caml_fs_register(name_a_,content_b_);
      else
       {if(!joo_global_object_c_.caml_fs_tmp)
         joo_global_object_c_.caml_fs_tmp=[];
        joo_global_object_c_.caml_fs_tmp.push
         ({name:name_a_,content:content_b_})}
      return 0}
    caml_fs_register_extern_a_
     ("/cmis/jsooTop.cmi",
      "Caml1999I017\x84\x95\xa6\xbe\0\0\x02\xb3\0\0\0\x95\0\0\x02\x18\0\0\x02\x07\xa0'JsooTop\xa0\xa0\xb0\x01\x03\xf5#use@\xc0\xb0\xc1 \xb0\xb3\xb1\x90\xb0@&FormatA)formatter\0\xff@\x90@\x02\x05\xf5\xe1\0\0\xfa\xb0\xc1\x04\x0b\xb0\xb3\x90\xb0C&string@@\x90@\x02\x05\xf5\xe1\0\0\xfb\xb0\xb3\x90\xb0E$bool@@\x90@\x02\x05\xf5\xe1\0\0\xfc@\x02\x05\xf5\xe1\0\0\xfd@\x02\x05\xf5\xe1\0\0\xfe@\xb0\xc0&_none_A@\0\xff\x04\x02A@\xa0\xa0\xb0\x01\x03\xf6'execute@\xc0\xb0\xc1\x04!\xb0\xb3\x04\x10@\x90@\x02\x05\xf5\xe1\0\0\xf0\xb0\xc1(?pp_code\xb0\xb3\x90\xb0J&option@\xa0\xb0\xb3\xb1\x04,\x04)\0\xff@\x90@\x02\x05\xf5\xe1\0\0\xf1@\x90@\x02\x05\xf5\xe1\0\0\xf2\xb0\xc1\x044\xb0\xb3\xb1\x043\x040\0\xff@\x90@\x02\x05\xf5\xe1\0\0\xf3\xb0\xc1\x04:\xb0\xb3\x04/@\x90@\x02\x05\xf5\xe1\0\0\xf4\xb0\xb3\x90\xb0F$unit@@\x90@\x02\x05\xf5\xe1\0\0\xf5@\x02\x05\xf5\xe1\0\0\xf6@\x02\x05\xf5\xe1\0\0\xf7@\x02\x05\xf5\xe1\0\0\xf8@\x02\x05\xf5\xe1\0\0\xf9@\x04,@\xa0\xa0\xb0\x01\x03\xf7*initialize@\xc0\xb0\xc1\x04J\xb0\xb3\x04\r@\x90@\x02\x05\xf5\xe1\0\0\xed\xb0\xb3\x04\x10@\x90@\x02\x05\xf5\xe1\0\0\xee@\x02\x05\xf5\xe1\0\0\xef@\x049@\xa0\xa0\xb0\x01\x03\xf83get_camlp4_syntaxes@\xc0\xb0\xc1\x04W\xb0\xb3\x04\x1a@\x90@\x02\x05\xf5\xe1\0\0\xe9\xb0\xb3\x90\xb0I$list@\xa0\xb0\xb3\x04U@\x90@\x02\x05\xf5\xe1\0\0\xea@\x90@\x02\x05\xf5\xe1\0\0\xeb@\x02\x05\xf5\xe1\0\0\xec@\x04M@\xa0\xa0\xb0\x01\x03\xf96register_camlp4_syntax@\xc0\xb0\xc1\x04k\xb0\xb3\x04`@\x90@\x02\x05\xf5\xe1\0\0\xdc\xb0\xc1\x04p\xb0\xc1\x04r\xb0\xc1\x04t\xb0\x92\xa0\xb0\xb3\x04l@\x90@\x02\x05\xf5\xe1\0\0\xe0\xa0\xb0\xc1\x04}\xb0\xb3\x04@@\x90@\x02\x05\xf5\xe1\0\0\xdd\xb0\xb3\x04C@\x90@\x02\x05\xf5\xe1\0\0\xde@\x02\x05\xf5\xe1\0\0\xdf@\x02\x05\xf5\xe1\0\0\xe1\xb0\xb3\x04F@\x90@\x02\x05\xf5\xe1\0\0\xe2@\x02\x05\xf5\xe1\0\0\xe3\xb0\xb3\x04I@\x90@\x02\x05\xf5\xe1\0\0\xe4@\x02\x05\xf5\xe1\0\0\xe5\xb0\xb3\x04L@\x90@\x02\x05\xf5\xe1\0\0\xe6@\x02\x05\xf5\xe1\0\0\xe7@\x02\x05\xf5\xe1\0\0\xe8@\x04u@@\x84\x95\xa6\xbe\0\0\0\x9f\0\0\0\x19\0\0\0[\0\0\0J\xa0\xa0'JsooTop\x900\b\x99\xe3\xab\xe3\x1f\xff\xb8\xdf\xb0yS\xb88#$\xa0\xa0*Pervasives\x900\r\x01ZZ!6e\x9b\r\xe41\xbe\x7f\x15E\xbe\xa0\xa0&Format\x900a\xd45\x02B\xb3\0x\xd3\xad\x96\xc9\x04\xc9\xf7\xa1\xa0\xa08CamlinternalFormatBasics\x900\xba\x1b\xe6.\xb4Z\xbdC\\u\xcbY\xccF\xb9\"\xa0\xa0&Buffer\x900\xa5y\xf4\xa5~0\x0e\xc7U\xf8J\xf8\x83\xc1\xe5\x1b@\x84\x95\xa6\xbe\0\0\0\x01\0\0\0\0\0\0\0\0\0\0\0\0@");
    return}
  (function(){return this}()));
