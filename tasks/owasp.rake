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
  # To pass additional owasp ant task options: 
  # project.owasp.dependency_check_options = { :projectName=>"Test-Dependency-Check", :reportFormat=>"XML" }

  module OWASP

    VERSION = "3.3.1"
    REQUIRES = Buildr.struct(
                :owasp => Buildr.group("dependency-check-ant",
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
                 :commons => ["org.apache.commons:commons-lang3:jar:3.7",
                            "org.apache.commons:commons-text:jar:1.3",
                            "org.apache.commons:commons-compress:jar:1.17"],
                 :misc => ["org.slf4j:slf4j-api:jar:1.7.12",
                          "org.apache.velocity:velocity:jar:1.7",
                          "org.glassfish:javax.json:jar:1.0.4",
                          "org.json:json:jar:20140107",
                          "org.jsoup:jsoup:jar:1.11.3",
                          "commons-collections:commons-collections:jar:3.2.2",
                          "commons-io:commons-io:jar:2.6",
                          "commons-lang:commons-lang:jar:2.4",
                          "com.github.spullara.mustache.java:compiler:jar:0.8.17",
                          "com.google.code.gson:gson:jar:2.8.5",
                          "com.google.guava:guava:jar:16.0.1",
                          "com.h2database:h2:jar:1.4.196",
                          "com.sun.mail:mailapi:jar:1.6.1",
                          "com.esotericsoftware:minlog:jar:1.3",
                          "com.h3xstream.retirejs:retirejs-core:jar:3.0.1",
                          "com.vdurmont:semver4j:jar:2.2.0",
                          "javax.activation:activation:jar:1.1",
                          "joda-time:joda-time:jar:1.5"]
               )

        class << self

          def invoke_dependency_check(deps,options,classpath)
            Buildr.ant('dependency_check') do |ant|
              ant.taskdef :name => "dependency_check", :classname => "org.owasp.dependencycheck.taskdefs.Check", :classpath => classpath

              # check if project has compile.dependencies
              if (deps.any?)
                ant.dependency_check options do
                  deps.each do |dep|
                    depname = dep.to_s
                    puts "checking jar:" + File.basename(depname)
                    ant.filelist :dir=> File.dirname(depname), :files=> File.basename(depname)
                  end
                end
              end

            end
          end

          def get_project_dependencies(deps,proj)
            if proj.compile.dependencies.any?
              Buildr.artifacts(proj.compile.dependencies).each { |a| a.invoke() if a.respond_to?(:invoke) }.flatten.each { |b| deps << b if !deps.include? b }
            end
          end

          def dependency_check_project(proj, options)
            deps = []

            #get current project dependencies
            get_project_dependencies(deps, proj)

            #get sub projects dependencies
            proj.projects.each { |p| get_project_dependencies(deps, p) } if proj.projects.any?

            cp = Buildr.artifacts(REQUIRES).each { |a| a.invoke() if a.respond_to?(:invoke) }.map(&:to_s).join(File::PATH_SEPARATOR)

            puts "Dependency check for project started: " + proj.name
            invoke_dependency_check(deps,options,cp)
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
              puts "OWASP Dependency task is enabled"
              project.task('dependency_check') do
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
