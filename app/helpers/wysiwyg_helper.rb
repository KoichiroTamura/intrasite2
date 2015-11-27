=begin

Copyright (c) 2015, Koichiro Tamura/Toshinari Naminatsu/Yuki Ishikawa/Tatsuya Onishi/Mamoru Endo/Kenji Suzuki

This software is released under the BSD 2-Clause License.

http://opensource.org/licenses/BSD-2-Clause

=end

module WysiwygHelper
  
  def render_wygiwyg_editor(id)
    javascript_tag do 
<<EOF
    tinyMCE.init({
      content_css : "/javascripts/tiny_mce/wysiwyg.css",
      language: "ja",
      mode : "exact",
      elements: "#{id}",
      theme : 'advanced',
      border: '1px solid black',
      convert_urls : true,
      submit_patch : false,
      accessibility_warnings : false,
      cleanup : true,
      plugins : "pagebreak,style,layer,table,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template,advlist",
      onchange_callback: function(inst){inst.save();window.status='Transfaerd'+inst.editorId},
      remove_instance_callback : function(){this.save();},
      // Theme options
      theme_advanced_buttons1 : "fontselect,fontsizeselect,formatselect,forecolor,backcolor,|,bold,italic,underline,strikethrough,|,sup,sub", 
      theme_advanced_buttons2 : "justifyleft,justifycenter,justifyright,justifyfull,|,bullist,numlist,|, outdent,indent,|,link,unlink,|,hr,|,table,image,|,styleprops,|,help,cleanup,code",
      theme_advanced_buttons3 : "",
      theme_advanced_toolbar_location : "top",
      theme_advanced_toolbar_align : "left",
      theme_advanced_statusbar_location : "bottom",
      theme_advanced_resizing : true,
      handle_event_callback : function(e){tinyMCE.get("#{id}").save();}
      }); 

EOF
    end
  end

  # overriding
  # modified by Tamura for reflecting index info. 2010/08/21
  def text_area(object_name, method, options)
    index = options[:index]
    prefix = index ? object_name.to_s + "[#{index}]" : object_name.to_s
    obj =  options[:object].attributes

    num = UUIDTools::UUID.random_create.to_s

    res = "<table style='border:0px' border=0><tr>"
    res += "<td style='border:0px;text-align:right;margin:0;padding:0;line-height:0'>" + link_to(image_tag('html_tag.png',:id=>"#{prefix}_#{method}_#{num}_html",:style=>"background:#efefef;border:0px;border-bottom:1px solid #efefef"),"javascript://",:onclick=>"tinyMCE.get(\"#{prefix}_#{method}_#{num}\").show();$(\"#{prefix}_#{method}_#{num}_text\").style.borderBottom=\"1px solid #cfcfcf\";$(\"#{prefix}_#{method}_#{num}_html\").style.borderBottom=\"1px solid #efefef\";$(\"#{prefix}_#{method}_#{num}_html\").style.background=\"#efefef\";$(\"#{prefix}_#{method}_#{num}_text\").style.background=\"#cfcfcf\";")
    res += link_to(image_tag('text_tab.png',:id=>"#{prefix}_#{method}_#{num}_text",:style=>"background:#cfcfcf;border:0px;border-bottom:1px solid #cfcfcf"),"javascript://",:onclick=>"tinyMCE.get(\"#{prefix}_#{method}_#{num}\").save();tinyMCE.get(\"#{prefix}_#{method}_#{num}\").hide();$(\"#{prefix}_#{method}_#{num}_text\").style.background=\"#efefef\";$(\"#{prefix}_#{method}_#{num}_html\").style.background=\"#cfcfcf\";$(\"#{prefix}_#{method}_#{num}_text\").style.borderBottom=\"1px solid #cfcfcf\";$(\"#{prefix}_#{method}_#{num}_html\").style.borderBottom=\"1px solid #cfcfcf\";")
    res += "</td></tr><tr><td style='text-align:right;margin:0;padding:0;line-height:0'>"
    res += "<textarea ";
    res += " id='#{prefix}_#{method}_#{num}'" 
    res += " name='#{prefix}[#{method}]'"
    (options[:html_options] && options[:html_options].class.to_s=="String") and res += " #{options[:html_options]}" 
    (options[:html_options] && options[:html_options].class.to_s=="Hash") and options[:html_options].each do |k,v|
      res += " ${k}='#{v}'"
    end
    res += ">"
    if (obj[method] && obj[method].length>0)
      res += obj[method].to_s
    end
    res += "</textarea>"
    res += "</td></tr></table>"
    options[:non_html] or res += render_wygiwyg_editor("#{prefix}_#{method}_#{num}")
    res
  end

end