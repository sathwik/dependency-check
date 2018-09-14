#
#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

gem "buildr", "~>1.5.3"
require "buildr"
#require "buildr/jetty"

require File.join(File.dirname(__FILE__), 'dependencies.rb')
require File.join(File.dirname(__FILE__), 'repositories.rb')

desc "Dependency-Check"

define "Dependency-Check" do
  
  Java.verbose
  project.version = '0.0.1'
  project.group = "org.example"

  project.owasp.enabled = "true" unless ENV["DEPENDENCY_CHECK"] =~ /^(no|off|false|skip)$/i
  project.owasp.dependency_check_options = { :projectName=>"Test-Dependency-Check", :reportFormat=>"XML" }

  compile.options.source = "1.8"
  compile.options.target = "1.8"

  task "compile" => ["dependency_check"]

  define "utils" do
    compile.with SLF4J   
    package :jar
  end
    
  define "utils2" do       
    package :jar
  end
end