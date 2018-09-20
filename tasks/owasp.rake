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

module Buildr
  # OWASP Dependency Check Plugin. 
  # By default its off for the project, to enable the check add <CODE>project.owasp.dependency_check = true</CODE> to your build file.
  # To pass additional owasp command options: 
  # <CODE>
  # project.owasp.dependency_check_options = { "--project" => project.name, 
  #                                            "-f"=>"HTML",
  #                                            "-o"=>project.path_to("target"),
  #                                            "-d"=>"/tmp" }
  # </CODE>

  module OWASP

    VERSION = "3.3.2"

    REQUIRES = Buildr.struct(
                :owasp => Buildr.group("dependency-check-cli",
                            "dependency-check-core",
                            "dependency-check-utils",
                            :under=>"org.owasp",
                            :version=>"#{VERSION}"),
                :lucene => Buildr.group("lucene-analyzers-common",
                            "lucene-core",
                            "lucene-queries",
                            "lucene-queryparser",
                            "lucene-sandbox",
                            :under=>"org.apache.lucene",
                            :version=>"5.5.5"),
                 :commons => ["org.apache.commons:commons-lang3:jar:3.8",
                            "org.apache.commons:commons-text:jar:1.3",
                            "org.apache.commons:commons-compress:jar:1.18"],
                 :misc => ["org.slf4j:slf4j-api:jar:1.7.25",
                          "org.apache.velocity:velocity:jar:1.7",
                          "org.apache.ant:ant:jar:1.9.9",
                          "org.glassfish:javax.json:jar:1.0.4",
                          "org.json:json:jar:20140107",
                          "org.jsoup:jsoup:jar:1.11.3",
                          "commons-collections:commons-collections:jar:3.2.2",
                          "commons-io:commons-io:jar:2.6",
                          "commons-lang:commons-lang:jar:2.4",
                          "commons-cli:commons-cli:jar:1.4",
                          "com.github.spullara.mustache.java:compiler:jar:0.8.17",
                          "com.google.code.gson:gson:jar:2.8.5",
                          "com.google.guava:guava:jar:16.0.1",
                          "com.h2database:h2:jar:1.4.196",
                          "com.sun.mail:mailapi:jar:1.6.2",
                          "com.esotericsoftware:minlog:jar:1.3",
                          "com.h3xstream.retirejs:retirejs-core:jar:3.0.1",
                          "com.vdurmont:semver4j:jar:2.2.0",
                          "javax.activation:activation:jar:1.1",
                          "joda-time:joda-time:jar:1.6",
                          "ch.qos.logback:logback-core:jar:1.2.3",
                          "ch.qos.logback:logback-classic:jar:1.2.3"]
               )

        class << self

          def invoke_dependency_check(deps,options)
            Buildr.artifacts(REQUIRES).each { |a| a.invoke() if a.respond_to?(:invoke) }

            #OWASP CMD Line
            all_args = []
            Buildr.artifacts(deps).each { |a| a.invoke() if a.respond_to?(:invoke) }.map(&:to_s).each { |d| all_args << "-s"  << d }

            all_args << options.to_a.flatten
            Java::Commands.java "org.owasp.dependencycheck.App", *all_args, :classpath=>REQUIRES
          end

          def get_project_dependencies(proj)
            deps = []
            if proj.compile.dependencies.any?
              Buildr.artifacts(proj.compile.dependencies).each { |a| a.invoke() if a.respond_to?(:invoke) }.flatten.each { |b| deps << b if !deps.include? b }
            end
            deps
          end

          def dependency_check_project(proj, options)
            deps = []

            #get current project dependencies
            deps << get_project_dependencies(proj)

            #get sub projects dependencies
            proj.projects.each { |p| deps << get_project_dependencies(p) } if proj.projects.any?

            invoke_dependency_check(deps,options)
          end

        end

        class Config
          attr_accessor :enabled

          def enabled?
            !!@enabled
          end

          attr_writer :dependency_check_options

          def dependency_check_options
              @dependency_check_options.nil? ? {} : @dependency_check_options
          end

          attr_reader :project

          def initialize(project)
            @project = project
          end

        end

        module ProjectExtension
          include Extension

          def owasp
            @owasp ||= Buildr::OWASP::Config.new(project)
          end

          after_define do |project|
            if project.owasp.enabled?
              project.task('dependency_check') do
                puts "Dependency check started " + project.name
                Buildr::OWASP.dependency_check_project(project, project.owasp.dependency_check_options)
              end
            end
          end
        end
    end
end

class Buildr::Project
  include Buildr::OWASP::ProjectExtension
end
