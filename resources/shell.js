
var Line = Class.create({
  initialize: function(detail) {
    this.detail = detail
  },
  
  title: function() {
    if(typeof this.detail == 'string')
      return this.detail;
    else
      return this.detail.text;
  },
  
  info: function() {
    return null
  }

  
});


Line.for_detail = function(detail) {
  if(typeof detail == 'string') {
    return new Line(detail)

  } else {
    switch(detail.kind) {
      case 'sql':
        return new SqlLine(detail)
      case 'render':
        return new RenderLine(detail)
      case 'backtrace':
        return new BacktraceLine(detail)
      default:
        return new Line(detail)
    }
  }
}

// TODO improve sql rendering
// TODO add click-to-copy for sql
var SqlLine = Class.create(Line,{
  title: function() {
    return this.detail.name
  },
  
  info: function() {
    return this.detail.sql
  },
  
  class_name: 'sql-line'
})

var RenderLine = Class.create(Line,{
  title: function(full) {
    if(full)
      return this.detail.tense+" "+this.detail.template
    else
      return this.detail.template
  },
  
  info: function(full) {
    var text = $A()
    var joiner = full ? '<br/>' : ''
    
    if(this.detail.within)
      text.push(this.detail.within)
      
    if(this.detail.time)
      text.push("in " + this.detail.time + "s")
    
    return text.join(joiner);
  },
  
  class_name: 'render-line'
})

var BacktraceLine = Class.create(Line,{
  
  bt_template: new Template('<a href="logeye:editbacktrace/path=#{path}&line=#{line}">#{short_path}</a>'),
  
  title: function() {
    var gem = this.kind_img()

    return gem+this.bt_template.evaluate({RAILS_ROOT:'RAILS_ROOT',
      path:this.detail.path,
      short_path: this.detail.short_path,
      line:this.detail.line,
      method:this.detail.method
    })
  },
  
  gem: function() {
    return this.detail.path_kind == 'gem'
  },

  app: function() {
    return this.detail.path_kind == 'app'
  },
  kind_img: function() {
    switch(this.detail.path_kind) {
      case 'gem':
        return '<img src="gem.png"/> '
      case 'app':
        return '<img src="btapp.png"/> '
      default:
        return '<img src="btcore.png"/> '
    }
  },
  
  info: function(full) {
    if(full) {
      var text = 'line '+this.detail.line+'<br/> in method '+this.detail.method
      if(typeof this.detail.gem == 'string') {
        text += '<br/> from gem '+this.detail.gem
      }
      return text
    } else {
      var text = this.detail.line+' in '+this.detail.method

      if(typeof this.detail.gem == 'string') {
        text = this.detail.gem+':'+text
      }
      return text
    }
  },
  
  class_name: 'backtrace-line'
  
});


var Entry = Class.create({
  initialize: function(detail,index) {
    this.detail = detail;
    this.index = index;
    
    this.content = Line.for_detail(detail)
    
    this.build_dom();
    
    this.div.observe('click',this.toggleSize.bindAsEventListener(this))
  },
  
  build_dom: function() {
    var cls = (this.index & 1) ? 'even' : 'odd'
    
    this.div = new Element('li', {'class': cls})
    

    this.compact_line = new Element('span', {'class':'compact-line line'})
    this.compact_line_title = new Element('span', {'class':'title'})
    this.compact_line_detail = new Element('span', {'class':'info'})
    
    this.compact_line.appendChild(this.compact_line_title)
    this.compact_line.appendChild(this.compact_line_detail)
    
    this.full_line    = new Element('span', {'class':'full-line line',style:'display:none'})
    this.full_line_title = new Element('span', {'class':'title'})
    this.full_line_detail = new Element('span', {'class':'info'})
    
    this.full_line.appendChild(this.full_line_title)
    this.full_line.appendChild(this.full_line_detail)
    
    this.build_line()
    this.build_compact()
    this.build_full()
    
    this.div.appendChild(this.compact_line)
    this.div.appendChild(this.full_line)

  },
  
  has_overflow: function() {
    var gfx_overflow = this.div.scrollWidth > this.div.offsetWidth
    return this.content.can_expand(gfx_overflow)
  },
  
  build_line: function() {
    if(d = this.content.class_name)
      this.div.addClassName(d)
  },
  
  build_compact: function() {  
    this.compact_line_title.update(this.content.title());
    if(d = this.content.info())
      this.compact_line_detail.update(d);
  },
  
  build_full: function() {
    this.full_line_title.update(this.content.title(true));
    if(d = this.content.info(true))
      this.full_line_detail.update(d);
  },
  
  set_compact: function() {
    if(this.is_compact) return
    
    this.compact_line.show()
    this.full_line.hide()
    this.is_compact = true

    this.div.removeClassName('full')
    this.div.addClassName('compact')
    this.div.removeClassName('oflow')
  },
  
  set_full: function() {
    if(!this.is_compact) return
    
    this.is_compact = false
    
    this.compact_line.hide()
    this.full_line.show()
    
    this.div.removeClassName('compact')
    this.div.removeClassName('oflow')
    this.div.addClassName('full')
  },
  
  // TODO add toggle all others to small
  toggleSize: function() {
    if(this.is_compact) {
      Page.close_all_except(this)
      this.set_full()
    } else {
      this.set_compact()
    }
  }
  
});


var Page = {  
  ctl_act_template: new Template('<a href="logeye:editcontroller">#{controller}/#{action}</a>'),
  
  ctl_act: function(controller,action) {
    $('ctl_act').innerHTML = this.ctl_act_template.evaluate({controller:controller,action:action})
  },
  
  mkEntry: function(detail,i) {
    var e = new Entry(detail,i)
    this.container.insert(e.div)
    e.set_compact()
    return e
  },
  
  setEntry: function(entry) {
    // this.calc_width()
    
    // alert("setting entry "+entry)
 
    
    if(entry.controller && entry.action) {
      $('head').show();

      this.ctl_act(entry.controller,entry.action);
      
      if(entry.verb)
        entry.verb = entry.verb.toUpperCase()

      $w('requested_at ip verb http_code parameters').each(function(w) {
        $(w).update(entry[w])
      })
    } else {
      $('head').hide();
    }

    
    if(entry.details) {
      $('detail-section').show();
      var i = 0;
      this.container = $('details');
      this.container.update('')
      this.entries = entry.details.collect(function(detail) {
                        i += 1
                        return Page.mkEntry(detail,i)
                      });

      
    } else {
      $('detail-section').hide();
    }
  },
  
  close_all_except: function(exception) {
    this.entries.each(function(e) {
      if(e != exception)
        e.set_compact()
    })
  }
}


// Event.observe(window,'load',function() {
  // var json = {"ip":"10.211.55.3","verb":"post","session_id":"d1a81e27725926f958465edeae8091bf","requested_at":"Sat Sep 22 17:08:23 +1000 2007","details":[{"text":"Processing StudentsController#create (for 10.211.55.3 at 2007-09-22 17:08:23) [POST]\n"},{"time":"0.000407","name":"User Load ","kind":"sql","sql":"SELECT * FROM users WHERE (users.`id` = 5) LIMIT 1"},{"text":"parse_authorization_expression pre instance_eval  process_role('parent') \n"},{"text":"process_role parent\n"},{"time":"0.000140","name":"SQL ","kind":"sql","sql":"BEGIN"},{"time":"0.000367","name":"Student Load ","kind":"sql","sql":"SELECT * FROM users WHERE (LOWER(users.login) = 'toby1') AND ( (users.`type` = 'Student' ) ) LIMIT 1"},{"time":"0.000570","name":"SQL ","kind":"sql","sql":"INSERT INTO users (`reset_hash_created_at`, `salt`, `activated_at`, `updated_at`, `crypted_password`, `grade_id`, `activation_code`, `admin`, `remember_token_expires_at`, `type`, `remember_token`, `first_name`, `reset_hash`, `last_name`, `login`, `parent_id`, `student_password`, `created_at`, `email`, `school_id`) VALUES(NULL, '5ee82d05f6107da711bcf0958c377f5efe04e9fd', '2007-09-22 07:08:23', '2007-09-22 17:08:23', '45ea11cedbfab4d9938d37d94afcb10b5c9d4b3b', NULL, 'de1ed8230d11cfc2e49f36a79d8be3e432407d4a', 0, NULL, 'Student', NULL, 'Toby', NULL, 'Cox', 'toby1', 5, 'kin73', '2007-09-22 17:08:23', NULL, NULL)"},{"text":"ferret_create\/update: Student : 19\n"},{"text":"creating doc for class: Student, id: 19\n"},{"text":"Adding field last_name with value 'Cox' to index\n"},{"text":"Adding field first_name with value 'Toby' to index\n"},{"text":"Adding field login with value 'toby1' to index\n"},{"text":"Adding field email with value '' to index\n"},{"time":"0.001609","name":"SQL ","kind":"sql","sql":"COMMIT"},{"time":"0.000397","name":"Pack Load ","kind":"sql","sql":"SELECT * FROM packs LIMIT 1"},{"time":"0.037146","name":"Payment Columns ","kind":"sql","sql":"SHOW FIELDS FROM payments"},{"time":"0.000232","name":"SQL ","kind":"sql","sql":"BEGIN"},{"time":"0.000325","name":"SQL ","kind":"sql","sql":"INSERT INTO payments (`status`, `updated_at`, `code`, `total`, `invalidated`, `parent_id`, `created_at`) VALUES('completed', '2007-09-22 17:08:23', NULL, 2500, 0, 5, '2007-09-22 17:08:23')"},{"time":"0.000961","name":"SQL ","kind":"sql","sql":"COMMIT"},{"time":"0.000134","name":"SQL ","kind":"sql","sql":"BEGIN"},{"time":"0.000717","name":"SQL ","kind":"sql","sql":"INSERT INTO purchases (`status`, `updated_at`, `student_id`, `pack_id`, `payment_id`, `position`, `created_at`) VALUES('completed', '2007-09-22 17:08:23', 19, 1, 36, NULL, '2007-09-22 17:08:23')"},{"time":"0.000802","name":"SQL ","kind":"sql","sql":"COMMIT"},{"text":"Sent mail:\n"},{"text":" Date: Sat, 22 Sep 2007 17:08:23 +1000\r\n"},{"text":"From: lachiec@gmail.com\r\n"},{"text":"To: lachiec@gmail.com\r\n"},{"text":"Subject: [READING EGGS] Student Toby Cox Created\r\n"},{"text":"Mime-Version: 1.0\r\n"},{"text":"Content-Type: text\/plain; charset=utf-8\r\n"},{"text":"Hi Lachie,\n"},{"text":"Here are the details for the student you created:\n"},{"text":"Name: Toby Cox\n"},{"text":"Login: toby1\n"},{"text":"Password: kin73\n"},{"text":"regards,\n"},{"text":"The Reading Egg team\n"},{"text":"Timeout::Error (execution expired):\n"},{"path_kind":"lib","short_path":"timeout.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/timeout.rb","gem":null,"method":"rbuf_fill","line":"54","kind":"backtrace"},{"path_kind":"lib","short_path":"timeout.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/timeout.rb","gem":null,"method":"timeout","line":"56","kind":"backtrace"},{"path_kind":"lib","short_path":"timeout.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/timeout.rb","gem":null,"method":"timeout","line":"76","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/protocol.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/protocol.rb","gem":null,"method":"rbuf_fill","line":"132","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/protocol.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/protocol.rb","gem":null,"method":"readuntil","line":"116","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/protocol.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/protocol.rb","gem":null,"method":"readline","line":"126","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/smtp.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/smtp.rb","gem":null,"method":"recv_response","line":"664","kind":"backtrace"},{"path_kind":"app","short_path":"lib\/smtp_tls.rb","path":"lib\/smtp_tls.rb","gem":null,"method":"do_start","line":"14","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/smtp.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/smtp.rb","gem":null,"method":"critical","line":"686","kind":"backtrace"},{"path_kind":"app","short_path":"lib\/smtp_tls.rb","path":"lib\/smtp_tls.rb","gem":null,"method":"do_start","line":"14","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/smtp.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/smtp.rb","gem":null,"method":"start","line":"378","kind":"backtrace"},{"path_kind":"lib","short_path":"net\/smtp.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/net\/smtp.rb","gem":null,"method":"start","line":"316","kind":"backtrace"},{"path_kind":"gem","short_path":"action_mailer\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionmailer-1.3.3\/lib\/action_mailer\/base.rb","gem":"actionmailer-1.3.3","method":"perform_delivery_smtp","line":"565","kind":"backtrace"},{"path_kind":"gem","short_path":"action_mailer\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionmailer-1.3.3\/lib\/action_mailer\/base.rb","gem":"actionmailer-1.3.3","method":"send","line":"451","kind":"backtrace"},{"path_kind":"gem","short_path":"action_mailer\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionmailer-1.3.3\/lib\/action_mailer\/base.rb","gem":"actionmailer-1.3.3","method":"deliver!","line":"451","kind":"backtrace"},{"path_kind":"gem","short_path":"action_mailer\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionmailer-1.3.3\/lib\/action_mailer\/base.rb","gem":"actionmailer-1.3.3","method":"method_missing","line":"333","kind":"backtrace"},{"path_kind":"app","short_path":"app\/controllers\/students_controller.rb","path":"app\/controllers\/students_controller.rb","gem":null,"method":"create","line":"39","kind":"backtrace"},{"path_kind":"app","short_path":"vendor\/plugins\/authorization\/lib\/authorization.rb","path":"vendor\/plugins\/authorization\/lib\/authorization.rb","gem":null,"method":"permit","line":"58","kind":"backtrace"},{"path_kind":"app","short_path":"app\/controllers\/students_controller.rb","path":"app\/controllers\/students_controller.rb","gem":null,"method":"create","line":"33","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/base.rb","gem":"actionpack-1.13.3","method":"send","line":"1095","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/base.rb","gem":"actionpack-1.13.3","method":"perform_action_without_filters","line":"1095","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call_filter","line":"632","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call_filter","line":"634","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call_filter","line":"638","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call","line":"438","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call_filter","line":"637","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call_filter","line":"638","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call","line":"438","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"call_filter","line":"637","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"perform_action_without_benchmark","line":"619","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/benchmarking.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/benchmarking.rb","gem":"actionpack-1.13.3","method":"perform_action_without_rescue","line":"66","kind":"backtrace"},{"path_kind":"lib","short_path":"benchmark.rb","path":"\/opt\/local\/lib\/ruby\/1.8\/benchmark.rb","gem":null,"method":"measure","line":"293","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/benchmarking.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/benchmarking.rb","gem":"actionpack-1.13.3","method":"perform_action_without_rescue","line":"66","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/rescue.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/rescue.rb","gem":"actionpack-1.13.3","method":"perform_action","line":"83","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/base.rb","gem":"actionpack-1.13.3","method":"send","line":"430","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/base.rb","gem":"actionpack-1.13.3","method":"process_without_filters","line":"430","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/filters.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/filters.rb","gem":"actionpack-1.13.3","method":"process_without_session_management_support","line":"624","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/session_management.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/session_management.rb","gem":"actionpack-1.13.3","method":"process","line":"114","kind":"backtrace"},{"path_kind":"gem","short_path":"action_controller\/base.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/actionpack-1.13.3\/lib\/action_controller\/base.rb","gem":"actionpack-1.13.3","method":"process","line":"330","kind":"backtrace"},{"path_kind":"gem","short_path":"dispatcher.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/rails-1.2.3\/lib\/dispatcher.rb","gem":"rails-1.2.3","method":"dispatch","line":"41","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/rails.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/rails.rb","gem":"mongrel-1.0.1","method":"process","line":"78","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/rails.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/rails.rb","gem":"mongrel-1.0.1","method":"synchronize","line":"76","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/rails.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/rails.rb","gem":"mongrel-1.0.1","method":"process","line":"76","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"process_client","line":"618","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"each","line":"617","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"process_client","line":"617","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"run","line":"736","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"initialize","line":"736","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"new","line":"736","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"run","line":"736","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"initialize","line":"720","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"new","line":"720","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel.rb","gem":"mongrel-1.0.1","method":"run","line":"720","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/configurator.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/configurator.rb","gem":"mongrel-1.0.1","method":"run","line":"271","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/configurator.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/configurator.rb","gem":"mongrel-1.0.1","method":"each","line":"270","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/configurator.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/configurator.rb","gem":"mongrel-1.0.1","method":"run","line":"270","kind":"backtrace"},{"path_kind":"gem","short_path":null,"path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/bin\/mongrel_rails","gem":"mongrel-1.0.1\/bin\/mongrel_rails","method":"run","line":"127","kind":"backtrace"},{"path_kind":"gem","short_path":"mongrel\/command.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/lib\/mongrel\/command.rb","gem":"mongrel-1.0.1","method":"run","line":"211","kind":"backtrace"},{"path_kind":"gem","short_path":null,"path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/mongrel-1.0.1\/bin\/mongrel_rails","gem":"mongrel-1.0.1\/bin\/mongrel_rails","method":null,"line":"243","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"load","line":"488","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"load","line":"488","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"new_constants_in","line":"342","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"load","line":"488","kind":"backtrace"},{"path_kind":"gem","short_path":"commands\/servers\/mongrel.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/rails-1.2.3\/lib\/commands\/servers\/mongrel.rb","gem":"rails-1.2.3","method":null,"line":"60","kind":"backtrace"},{"path_kind":"lib","short_path":"rubygems\/custom_require.rb","path":"\/opt\/local\/lib\/ruby\/site_ruby\/1.8\/rubygems\/custom_require.rb","gem":null,"method":"gem_original_require","line":"27","kind":"backtrace"},{"path_kind":"lib","short_path":"rubygems\/custom_require.rb","path":"\/opt\/local\/lib\/ruby\/site_ruby\/1.8\/rubygems\/custom_require.rb","gem":null,"method":"require","line":"27","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"require","line":"495","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"new_constants_in","line":"342","kind":"backtrace"},{"path_kind":"gem","short_path":"active_support\/dependencies.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/activesupport-1.4.2\/lib\/active_support\/dependencies.rb","gem":"activesupport-1.4.2","method":"require","line":"495","kind":"backtrace"},{"path_kind":"gem","short_path":"commands\/server.rb","path":"\/opt\/local\/lib\/ruby\/gems\/1.8\/gems\/rails-1.2.3\/lib\/commands\/server.rb","gem":"rails-1.2.3","method":null,"line":"39","kind":"backtrace"},{"path_kind":"lib","short_path":"rubygems\/custom_require.rb","path":"\/opt\/local\/lib\/ruby\/site_ruby\/1.8\/rubygems\/custom_require.rb","gem":null,"method":"gem_original_require","line":"27","kind":"backtrace"},{"path_kind":"lib","short_path":"rubygems\/custom_require.rb","path":"\/opt\/local\/lib\/ruby\/site_ruby\/1.8\/rubygems\/custom_require.rb","gem":null,"method":"require","line":"27","kind":"backtrace"},{"path_kind":"unknown","short_path":".\/script\/server","path":".\/script\/server","gem":null,"method":null,"line":"3","kind":"backtrace"},{"template":"\/opt\/local\/lib\/ruby\/gems\/1","tense":"Rendering","kind":"render"}],"parameters":"{\"commit\"=&gt;\"Save this child\", \"action\"=&gt;\"create\", \"controller\"=&gt;\"students\", \"student\"=&gt;{\"password_confirmation\"=&gt;\"[FILTERED]\", \"first_name\"=&gt;\"Toby\", \"password\"=&gt;\"[FILTERED]\", \"parent_id\"=&gt;\"5\", \"login\"=&gt;\"toby1\", \"last_name\"=&gt;\"Cox\"}}","http_code":500,"controller":"StudentsController","action":"create"}
  // Page.setEntry(json)
  // alert("observed...load")
// });