<?xml version="1.0" encoding="UTF-8"?>

<!--
# Copyright 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
-->

<xsl:stylesheet method="html" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">

  <xsl:template match="github-dashdata">
    <xsl:variable name="dashboardname" select="@dashboard"/>
    <xsl:variable name="githuburl" select="@github_url"/>
    <xsl:variable name="orgname" select="organization/@name"/>
    <html>
      <head>
        <title>GitHub Dashboard: <xsl:value-of select='@dashboard'/><xsl:if test='@team'> Team</xsl:if></title>
        <meta charset="utf-8"/>

        <!-- Lots of CDN usage here - you should replace this if you want to control the source of the JS/CSS -->
        <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/octicons/3.1.0/octicons.css" />
        <link type="text/css" rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" />
        <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery.smartmenus/1.0.0/addons/bootstrap/jquery.smartmenus.bootstrap.min.css"/>
        <!-- xsl comment needed in JS to avoid an empty tag -->
        <script type="text/javascript" src="https://code.jquery.com/jquery-1.11.3.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/flot/0.8.3/jquery.flot.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/flot/0.8.3/jquery.flot.stack.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/flot/0.8.3/jquery.flot.pie.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.24.2/js/jquery.tablesorter.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery.smartmenus/1.0.0/jquery.smartmenus.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery.smartmenus/1.0.0/addons/bootstrap/jquery.smartmenus.bootstrap.min.js"><xsl:comment/></script>

<script type="text/javascript">
// Currently inline code; tempted to move to its own separate JSON/JavaScript file 
// when more pluggable charts are implemented
var charts = [];

charts['PieChart'] = JSON.parse('{ \
    "series": { \
      "pie": { \
        "show": true, \
        "grid": { \
            "borderWidth": 0 \
        } \
      } \
    }, \
    "colors": ["#0F6BA9", "#2FABE9"] \
}');

charts["BarChart"] = JSON.parse('{ \
    "series": { \
        "stack": true, \
        "bars": { "show": true, "barWidth": 0.6 } \
    }, \
    "xaxis": { \
        "ticks": [ \
          ["1", "1 hour"], \
          ["2", "3 hours"], \
          ["3", "9 hours"], \
          ["4", "1 day"], \
          ["5", "1 week"], \
          ["6", "1 month"], \
          ["7", "1 quarter"], \
          ["8", "1 year"], \
          ["9", "over 1 year"]  \
        ] \
    }, \
    "grid": { \
        "borderWidth": 0 \
    }, \
    "legend": { \
        "position": "ne" \
    }, \
    "colors": ["#0F6BA9"] \
}');

charts["LineChart"] = JSON.parse('{ \
  "series": { \
    "stack": true, \
    "lines": { \
      "show": true, \
      "lineWidth": "2" \
    }, \
    "points": { "show": true }, \
    "shadowSize": "2" \
  }, \
  "grid": { \
    "borderWidth": "0" \
  }, \
  "legend": { \
    "position": "nw" \
  }, \
  "colors": ["#0F8BC9", "#2FABE9"] \
}');

 function plotChart(chart,config) {
  var chartData, chartConfig;
  chartConfig=charts[config];   // Remove this when this section is split out of the generated HTML
  $.when(
    $.getJSON("json-data/"+chart+".json", function(json) {
        chartData = json;
    })
//    $.getJSON("chart-config/"+config+".json", function(json) {
//        chartConfig = json;
//    })
  ).then(function() {
    $.plot($("#"+chart+"Chart"), chartData.datasets, chartConfig)
  });

 }
</script>

        <!-- This is inline to make for a simpler deliverable -->
        <style>
            html{font-size:100%;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}
            body{margin:0;font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;font-size:12px;line-height:17px;color:#222222;background-color:#e8e8e8;}

            h1,h2,h3,h4,h5{margin:0;font-family:inherit;font-weight:700;line-height:1;color:#333333;text-rendering:optimizelegibility;}
            h1{font-size:30px;line-height:36px;}
            h2{font-size:24px;line-height:36px;}
            h3{font-size:18px;line-height:27px;}
            h4{font-size:14px;line-height:18px;}
            h5{font-size:12px;line-height:18px;}

            .caret{display:inline-block;width:0;height:0;vertical-align:top;border-top:4px solid #000000;border-right:4px solid transparent;border-left:4px solid transparent;content:"";}

            .well{min-height:20px;margin-bottom:20px;background-color:#ffffff;-webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px;padding:8px 12px;border:1px solid #eeeeee;-webkit-box-shadow:0 1px 2px #888888;-moz-box-shadow:0 1px 2px #888888;box-shadow:0 1px 2px #888888;}

            .data-grid{width:100%;}
            .data-grid thead{color:#999999;font-size:10px;border-bottom:1px solid #aaaaaa;text-align:left;}
            .data-grid thead th{font-weight:normal;}
            .data-grid td{vertical-align:top;font-size:10px;}
            .data-grid tbody tr{border-bottom:1px solid #e8e8e8;}
            .data-grid tbody tr:last-child{border-bottom:0px none #e8e8e8;}
            .data-grid a{font-weight:bold;}
            .data-grid thead th{text-transform:uppercase;color:#888;font-size:10px;font-weight:bold;}
            .data-grid td{line-height:14px;padding:5px 2px;}
            .data-grid-sortable{width:100%;}

            .tablesorter-header{cursor:pointer;white-space:nowrap;}
            .tablesorter-header.tablesorter-headerAsc .tablesorter-header-inner,.tablesorter-header.tablesorter-headerDesc .tablesorter-header-inner{color:#ff5522;}
            .tablesorter-header:hover{color:#ff5522;background-color:#f2f8fa;}

            .nav{margin-left:0;margin-bottom:17px;list-style:none;}

            .nav-tabs:before,.nav-tabs:after{display:table;content:"";line-height:0;}
            .nav-tabs:after{clear:both;}
            .navbar-nav{border-bottom:1px solid #ddd;}

            .dropdown-toggle .caret{border-top-color:#0088cc;border-bottom-color:#0088cc;margin-top:6px;}
            .dropdown-toggle:hover .caret,.dropdown-toggle:focus .caret{border-top-color:#ff5522;border-bottom-color:#ff5522;}
            .dropdown-toggle .caret{margin-top:8px;}

            /* Dashboard specific */
            .labelColor {padding: 3px;-webkit-box-shadow:0 1px 2px #888888;-moz-box-shadow:0 1px 2px #888888;box-shadow:0 1px 2px #888888;}
            #tabcontent {padding: 20px;}
        </style>

        <!-- This will fail - but if you drop a theme.css file in you can add your own Bootstrap Theme :) -->
        <link type="text/css" rel="stylesheet" href="bootstrap-theme.css" />
      </head>
      <body class="inverse">
        <ul class="nav nav-tabs pull-right" role="tablist">
          <li><a href="AllAccounts.html">All</a></li>
          <xsl:if test="metadata/navigation/login">
          <li class="dropdown">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
              Logins <span class="caret"></span>
            </a>
            <ul class="dropdown-menu" role="menu">
              <xsl:for-each select="metadata/navigation/login">
                <xsl:sort select="."/>
                <xsl:variable name="login" select="."/>
                <li><a href="{$login}.html"><xsl:value-of select="."/></a></li>
              </xsl:for-each>
            </ul>
          </li>
          </xsl:if>
          <xsl:if test="metadata/navigation/organization">
          <li class="dropdown">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
              Organizations <span class="caret"></span>
            </a>
            <ul class="dropdown-menu" role="menu">
              <xsl:for-each select="metadata/navigation/organization">
                <xsl:sort select="."/>
                <xsl:variable name="org" select="."/>
                <li><a href="{$org}.html"><xsl:value-of select="."/></a></li>
              </xsl:for-each>
            </ul>
          </li>
          </xsl:if>
        </ul>

        <div class="well">
          <xsl:variable name="logo" select="@logo"/>
          <xsl:variable name="orgDescription" select="organization/description"/>
          <h2>GitHub Dashboard: <xsl:if test="@logo"><a rel="tooltip" title="{$orgDescription}" href="{$githuburl}/{$orgname}"><img width="35" height="35" src="{$logo}&amp;s=35"/></a></xsl:if><xsl:value-of select='@dashboard'/><xsl:if test='@team'> Team</xsl:if></h2><br/>
          <div class="container" style="padding-left: 0px; padding-right: 0px;">
          <ul id="tabs" class="nav navbar-nav">
            <li class="active"><a href="#overview" data-toggle="tab">Overview</a></li>
            <li class="dropdown">
              <a class="dropdown-toggle" data-toggle="dropdown" href="#">Repositories <span class="caret"/></a>
              <ul class="dropdown-menu" role="menu">
                <li><a href="#repositories" data-toggle="tab">Repositories (<xsl:value-of select="count(repo)"/>)</a></li>
                <li><a href="#repometrics" data-toggle="tab">Repository Metrics (<xsl:value-of select="count(repo)"/>)</a></li>
                <li><a href="#repotraffic" data-toggle="tab">Repository Traffic (<xsl:value-of select="count(repo)"/>)</a></li>
                <xsl:if test="metadata/repo-reports/report">
                <li class="dropdown"><a class="dropdown-toggle" data-toggle="dropdown" href="#">Reports <span class="caret"></span></a>
                  <ul class="dropdown-menu" role="menu">
                    <xsl:for-each select="metadata/repo-reports/report">
                      <xsl:sort select="@name"/>
                      <xsl:variable name="report" select="@key"/>
                      <li><a href="#{$report}" data-toggle="tab"><xsl:value-of select="@name"/>(<xsl:value-of select="count(//reporting[@type=$report])"/>)</a></li> 
                    </xsl:for-each>
                  </ul>
                </li>
                </xsl:if>
              </ul>
            </li>
            <li class="dropdown">
              <a class="dropdown-toggle" data-toggle="dropdown" href="#">Triage <span class="caret"/></a>
              <ul class="dropdown-menu" role="menu">
                <li><a href="#issuemetrics" data-toggle="tab">Issue Metrics (<xsl:value-of select="count(repo)"/>)</a></li>
                <li><a href="#prmetrics" data-toggle="tab">PR Metrics (<xsl:value-of select="count(repo)"/>)</a></li>
                <li><a href="#issues" data-toggle="tab">Open Issues (<xsl:value-of select="count(repo/issues/issue[@pull_request='false'])"/>)</a></li>
                <li><a href="#pullrequests" data-toggle="tab">Open PRs (<xsl:value-of select="count(repo/issues/issue[@pull_request='true'])"/>)</a></li>
                <xsl:if test="metadata/issue-reports/report">
                <li class="dropdown"><a class="dropdown-toggle" data-toggle="dropdown" href="#">Reports <span class="caret"></span></a>
                  <ul class="dropdown-menu" role="menu">
                    <xsl:for-each select="metadata/issue-reports/report">
                      <xsl:sort select="@name"/>
                      <xsl:variable name="report" select="@key"/>
                      <li><a href="#{$report}" data-toggle="tab"><xsl:value-of select="@name"/>(<xsl:value-of select="count(//reporting[@type=$report])"/>)</a></li> 
                    </xsl:for-each>
                  </ul>
                </li>
                </xsl:if>
              </ul>
            </li>
            <li class="dropdown">
              <a class="dropdown-toggle" data-toggle="dropdown" href="#">User Management <span class="caret"/></a>
              <ul class="dropdown-menu" role="menu">
                <xsl:if test="team">
                <li><a href="#teams" data-toggle="tab">Teams (<xsl:value-of select="count(team)"/>)</a></li>
                </xsl:if>
                <xsl:if test="organization/member">
                <li><a href="#members" data-toggle="tab">Members (<xsl:value-of select="count(organization/member[not(@login=preceding::*/@login)])"/>)</a></li>
                </xsl:if>
                <xsl:if test="repo/collaborators/collaborator">
                <li><a href="#collaborators" data-toggle="tab">Collaborators (<xsl:value-of select="count(repo/collaborators/collaborator)"/>)</a></li>
                </xsl:if>
                <xsl:if test="metadata/user-reports/report">
                <li class="dropdown"><a class="dropdown-toggle" data-toggle="dropdown" href="#">Reports <span class="caret"></span></a>
                  <ul class="dropdown-menu" role="menu">
                    <xsl:for-each select="metadata/user-reports/report">
                      <xsl:sort select="@name"/>
                      <xsl:variable name="report" select="@key"/>
                      <li><a href="#{$report}" data-toggle="tab"><xsl:value-of select="@name"/>(<xsl:value-of select="count(//reporting[@type=$report and not(text()=preceding::reporting[@type=$report]/text())])"/>)</a></li> 
                    </xsl:for-each>
                  </ul>
                </li>
                </xsl:if>
              </ul>
            </li>
          </ul>
          </div>
          <div id="tabcontent" class="tab-content">

            <div class="tab-pane active" id="overview">

            <table cellpadding="10px" width="100%"><tr>
            <td class="left" style="vertical-align:top">
              <xsl:if test="count(organization)=1">
                <xsl:if test="organization/@type='login'">
                  <h4>User Account:</h4>
                </xsl:if>
                <xsl:if test="organization/@type='organization'">
                  <h4>Organization:</h4>
                </xsl:if>
                <table class="data-grid">
                  <xsl:if test="organization/@name"><tr><td>Login</td><td><xsl:value-of select="organization/@name"/></td></tr></xsl:if>
                  <xsl:if test="organization/name"><tr><td>Name</td><td><xsl:value-of select="organization/name"/></td></tr></xsl:if>
                  <xsl:if test="organization/url">
                    <xsl:variable name='org_url' select="organization/url"/>
                    <tr><td>URL</td><td><a href="{$org_url}"><xsl:value-of select="organization/url"/></a></td></tr>
                  </xsl:if>
                  <xsl:if test="organization/email"><tr><td>Email</td><td><xsl:value-of select="organization/email"/></td></tr></xsl:if>
                  <xsl:if test="organization/location"><tr><td>Location</td><td><xsl:value-of select="organization/location"/></td></tr></xsl:if>
                  <xsl:if test="organization/created_at"><tr><td>Create Date</td><td><xsl:value-of select="substring(organization/created_at,1,10)"/></td></tr></xsl:if>
                </table>
              </xsl:if>
              <xsl:if test="count(organization)>1">
                <h4>Accounts:</h4>
                <table class="data-grid">
                 <xsl:for-each select="organization">
                  <xsl:sort select="count(../repo[@org=current()/@name])" data-type="number" order="descending"/>
                  <xsl:variable name="orgname2" select="@name"/>
                  <xsl:variable name="logo2" select="@avatar"/>
                  <xsl:variable name="orgDescription2" select="organization/description"/>
                  <tr>
                    <td><xsl:if test="$logo2"><a rel="tooltip" title="{$orgDescription2}" href="{$githuburl}/{$orgname2}"><img width="35" height="35" src="{$logo2}&amp;s=35"/></a></xsl:if><a href="{$orgname2}.html"><xsl:value-of select="@name"/> (<xsl:value-of select="count(../repo[@org=current()/@name])"/>)</a></td>
                    <td></td>
                  </tr>
                 </xsl:for-each>
                </table>
              </xsl:if>
            </td>
            <td class="center" style="vertical-align:top">
                <h4>Repo Count over Time</h4><br/>
                <div id="{$dashboardname}-repoCountChart" style="height:150px;width:400px;"><xsl:comment/></div><br/>
            </td>
            <td class="right" style="vertical-align:top">
              <xsl:if test="repo">
              <h4>Recent Repositories:</h4>
              <table class='data-grid'>
                <xsl:for-each select="repo">
                  <xsl:sort select="@created_at" order="descending"/>
                  <xsl:variable name='repo_name' select="@name"/>
                  <xsl:variable name='orgname2' select="@org"/>
                  <xsl:if test="position() &lt;= 5">
                    <tr><td>
                      <xsl:value-of select='substring(@created_at,1,10)'/> - <a href="{$githuburl}/{$orgname2}/{$repo_name}"><xsl:value-of select='@name'/></a>
                      <xsl:if test="@private='true'">
                         <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                      </xsl:if>
                      <xsl:if test="@fork='true'">
                         <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                      </xsl:if>
                    </td></tr>
                  </xsl:if>
                </xsl:for-each>
              </table>
              </xsl:if>
              <xsl:if test="repo/release-data/release">
              <hr/>
              <h4>Recent Releases:</h4>
              <table class='data-grid'>
                <xsl:for-each select="repo/release-data/release">
                  <xsl:sort select="@published_at" order="descending"/>
                  <xsl:variable name='release_url' select="@url"/>
                  <xsl:if test="position() &lt;= 5">
                    <tr><td><xsl:value-of select='substring(@published_at,1,10)'/> - <a href="{$release_url}"><xsl:value-of select='../../@name'/>: <xsl:value-of select='.'/></a></td></tr>
                  </xsl:if>
                </xsl:for-each>
              </table>
              </xsl:if>
            </td></tr></table>

            </div>

            <div class="tab-pane" id="repositories">
             <div class="data-grid-sortable tablesorter">
              <table id='repoTable' class='data-grid'>
              <thead>
              <tr><th>Repository</th><th>Description</th><xsl:if test="team"><th>Teams</th></xsl:if>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="repo">
              <xsl:variable name="reponame" select="@name"/>
              <xsl:variable name="orgname2" select="@org"/>
              <xsl:variable name="homepage" select="@homepage"/>
                <tr><td>
                <a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/> (<xsl:value-of select="@org"/>)</a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>
                <td><xsl:value-of select="description"/><xsl:if test='@homepage!=""'> - <a href="{$homepage}"><xsl:value-of select="@homepage"/></a></xsl:if></td>
                 <xsl:if test="../team">
                  <td><ul style='list-style-type: none;'><xsl:for-each select='/github-dashdata/organization[@name=$orgname2]/team[repos/repo=$reponame]'>
                       <xsl:if test="@name != 'private read-only'">
                        <li><xsl:value-of select='@name'/></li>
                       </xsl:if>
                      </xsl:for-each></ul>
                  </td>
                 </xsl:if>
                </tr>
              </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="repometrics">
             <div class="data-grid-sortable tablesorter">
              <table id='repoMetricsTable' class='data-grid'>
              <thead>
              <tr><th>Repository</th><th><a href="#" rel="tooltip" title="As Reported by GitHub/Licensee with confidence percentage">Apparent License</a></th><th>Language</th>
                  <th>Created</th>
                  <th>Pushed</th>
                  <th>Updated</th>
                  <th><a href="#" rel="tooltip" title="Git Size in MB">Size</a></th>
                  <th><a href="#" rel="tooltip" title="# of Stars"><span class="octicon octicon-star"></span></a></th>
                  <th><a href="#" rel="tooltip" title="# of Watchers"><span class="octicon octicon-eye"></span></a></th>
                  <th><a href="#" rel="tooltip" title="# of Forks"><span class="octicon octicon-repo-forked"></span></a></th>
                  <th><a href="#" rel="tooltip" title="# of Commits"><span class="octicon octicon-git-commit"></span></a></th>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="repo">
              <xsl:variable name="orgname2" select="@org"/>
              <xsl:variable name="reponame" select="@name"/>
              <xsl:variable name="orgreponame" select="concat($orgname2, '/', $reponame)"/>
                <tr><td>
                <a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/> (<xsl:value-of select="@org"/>)</a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>
                <td>
                  <xsl:if test="/github-dashdata/repo/reports/license[@repo=$orgreponame]">
                    <xsl:variable name="licenseFile" select="/github-dashdata/repo/reports/license[@repo=$orgreponame]/@file"/>
                    <a href="{$githuburl}/{$orgname2}/{$reponame}/blob/master/{$licenseFile}"><xsl:value-of select="/github-dashdata/repo/reports/license[@repo=$orgreponame]"/> (<xsl:value-of select="round(/github-dashdata/repo/reports/license[@repo=$orgreponame]/@confidence)"/>%)</a>
                  </xsl:if>
                </td>
                <td><xsl:value-of select='@language'/></td>
                  <td><xsl:value-of select='substring(@created_at,1,10)'/></td>
                  <td><xsl:value-of select='substring(@pushed_at,1,10)'/></td>
                  <td><xsl:value-of select='substring(@updated_at,1,10)'/></td>
                  <td><xsl:value-of select="format-number(format-number(@size, '#.0') div 1024, '#.#')"/></td>
                  <td><xsl:value-of select='@stars'/></td>
                  <td><xsl:value-of select='@watchers'/></td>
                  <td><xsl:value-of select='@forks'/></td>
                  <td><xsl:value-of select='@commit_count'/></td>
                </tr>
              </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="repotraffic">
             <p><i>Shows the last 14 days of traffic.</i></p>
             <div class="data-grid-sortable tablesorter">
              <table id='repoTrafficTable' class='data-grid'>
              <thead>
              <tr><th>Repository</th>
                  <th>Views</th>
                  <th>Unique Views</th>
                  <th>Clones</th>
                  <th>Unique Clones</th>
                  <th>Top Referrer (views/uniques)</th>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="repo">
              <xsl:variable name="orgname2" select="@org"/>
              <xsl:variable name="reponame" select="@name"/>
              <xsl:variable name="orgreponame" select="concat($orgname2, '/', $reponame)"/>
                <tr><td>
                <a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/> (<xsl:value-of select="@org"/>)</a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>
                <td><xsl:value-of select='traffic-data/views/@count'/></td>
                <td><xsl:value-of select='traffic-data/views/@uniques'/></td>
                <td><xsl:value-of select='traffic-data/clones/@count'/></td>
                <td><xsl:value-of select='traffic-data/clones/@uniques'/></td>
                <td><xsl:value-of select='traffic-data/referrer'/> (<xsl:value-of select='traffic-data/referrer/@count'/>/<xsl:value-of select='traffic-data/referrer/@uniques'/>)</td>
                </tr>
              </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="issuemetrics">
             <table width="100%">
              <tr>
              <td style="text:align=left">
                <h4>Issue Count over Time</h4><br/>
                <div id="{$dashboardname}-issueCountChart" class="right" style="height:100px;width:300px;"><xsl:comment/></div><br/>
              </td>
              <td style="text:align=center">
                <h4>Time to Close an Issue</h4><br/>
                <div id="{$dashboardname}-issueTimeToCloseChart" style="height:100px;width:330px;"><xsl:comment/></div><br/>
              </td>
              <td style="text:align=right">
                <h4>Contributions</h4><br/>
                <div id="{$dashboardname}-issueCommunityPieChart" style="height:100px;width:270px;"><xsl:comment/></div><br/>
              </td>
              </tr>
             </table>
             <hr/>
             <div class="data-grid-sortable tablesorter">
              <table id='issueMetricsTable' class='data-grid'>
              <thead>
              <tr><th>Repository</th>
                  <th>Issues Opened</th>
                  <th>Issues Closed</th>
                  <th>Issue Total</th>
                  <th>Issue %age Closed</th>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="repo">
              <xsl:variable name="orgname2" select="@org"/>
              <xsl:variable name="reponame" select="@name"/>
              <xsl:variable name="orgreponame" select="concat($orgname2, '/', $reponame)"/>
                <tr><td>
                <a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/></a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>

                <td><xsl:value-of select='@open_issue_count'/></td>
                <td><xsl:value-of select='@closed_issue_count'/></td>
                <td><xsl:value-of select='@open_issue_count + @closed_issue_count'/></td>

                  <!-- Issue %age -->
                  <xsl:if test='@closed_issue_count=0 and @open_issue_count=0'>
                    <td>n/a</td>
                  </xsl:if>
                  <xsl:if test='@closed_issue_count!=0 or @open_issue_count!=0'>
                    <td><xsl:value-of select='round(100 * @closed_issue_count div (@open_issue_count + @closed_issue_count))'/>%</td>
                  </xsl:if>

                </tr>
              </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="prmetrics">
             <table width="100%">
              <tr>
              <td style="text:align=left">
                <h4>Pull Request Count over Time</h4><br/>
                <div id="{$dashboardname}-pullRequestCountChart" class="right" style="height:100px;width:300px;"><xsl:comment/></div><br/>
              </td>
              <td style="text:align=center">
                <h4>Time to Close a Pull Request</h4><br/>
                <div id="{$dashboardname}-prTimeToCloseChart" style="height:100px;width:330px;"><xsl:comment/></div><br/>
              </td>
              <td style="text:align=right">
                <h4>Contributions</h4><br/>
                <div id="{$dashboardname}-prCommunityPieChart" style="height:100px;width:270px;"><xsl:comment/></div><br/>
              </td>
              </tr>
             </table>
             <hr/>
             <div class="data-grid-sortable tablesorter">
              <table id='prMetricsTable' class='data-grid'>
              <thead>
              <tr><th>Repository</th>
                  <th>PRs Opened</th>
                  <th>PRs Closed</th>
                  <th>PR Total</th>
                  <th>PR %age Closed</th>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="repo">
              <xsl:variable name="orgname2" select="@org"/>
              <xsl:variable name="reponame" select="@name"/>
              <xsl:variable name="orgreponame" select="concat($orgname2, '/', $reponame)"/>
                <tr><td>
                <a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/></a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>

                <td><xsl:value-of select='@open_pr_count'/></td>
                <td><xsl:value-of select='@closed_pr_count'/></td>
                <td><xsl:value-of select='@open_pr_count + @closed_pr_count'/></td>

                  <!-- PR %age -->
                  <xsl:if test='@closed_pr_count=0 and @open_pr_count=0'>
                    <td>n/a</td>
                  </xsl:if>
                  <xsl:if test='@closed_pr_count!=0 or @open_pr_count!=0'>
                    <td><xsl:value-of select='round(100 * @closed_pr_count div (@open_pr_count + @closed_pr_count))'/>%</td>
                  </xsl:if>
                </tr>
              </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="issues">
             <div class="data-grid-sortable tablesorter">
              <table id='issueTable' class='data-grid'>
                <thead>
                <tr><th>Open Issue</th><th>Title</th><th>Labels</th><th>Age</th><th>Created</th><th>Updated</th><th>Requester</th><th>Comments</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="repo">
                  <xsl:variable name="orgname2" select="../@name"/>
                  <xsl:variable name="reponame" select="@name"/>
                  <xsl:for-each select="issues/issue[@pull_request='false']">
                    <xsl:variable name="issuekey" select="@number"/>
                    <xsl:variable name="title" select="title"/>
                    <xsl:variable name="membername" select="@user"/>
                    <tr>
                      <td><span class="octicon octicon-issue-opened"></span> <a href="{$githuburl}/{$orgname2}/{$reponame}/issues/{$issuekey}"><xsl:value-of select="$reponame"/>-<xsl:value-of select='@number'/></a></td>
                      <td>"<xsl:value-of select='substring(title,1,144)'/>"</td>
                      <td>
                       <xsl:for-each select='label'>
                        <xsl:variable name='labelColor' select='@color'/>
                        <span class='labelColor' style='background-color: #{$labelColor}'><xsl:value-of select='.'/></span>
                       </xsl:for-each>
                      </td>
                      <td><xsl:value-of select='@age'/>d</td>
                      <td><xsl:value-of select='substring(@created_at,1,10)'/></td>
                      <td><xsl:value-of select='substring(@updated_at,1,10)'/></td>
                      <td>
                      <xsl:if test="/github-dashdata/organization[@name=$orgname]/member[@login=$membername]">
                       <!-- TODO: How to allow users to pass in a url and member@internal to their internal directories? -->
                       <xsl:if test="$logo">
                        <span style="margin-right: 2px;"><sup><img src="{$logo}" width="8" height="8"/></sup></span>
                       </xsl:if>
                       <xsl:if test="not($logo)">
                        <span style="margin-right: 2px;"><sup>&#x2699;</sup></span>
                       </xsl:if>
                      </xsl:if>
                        <a href="{$githuburl}/{$membername}"><xsl:value-of select="@user"/></a>
                      </td>
                      <td><xsl:value-of select='@comments'/></td>
                    </tr>
                  </xsl:for-each>
                </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="pullrequests">
             <div class="data-grid-sortable tablesorter">
              <table id='prTable' class='data-grid'>
                <thead>
                <tr><th>Open Pull Request</th><th>Title</th><th>Labels</th><th>Age</th><th>Created</th><th>Updated</th><th>Requester</th><th>Comments</th><th># Files Changed</th><th># New Lines</th><th># Removed Lines</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="repo">
                  <xsl:variable name="orgname2" select="../@name"/>
                  <xsl:variable name="reponame" select="@name"/>
                  <xsl:for-each select="issues/issue[@pull_request='true']">
                    <xsl:variable name="issuekey" select="@number"/>
                    <xsl:variable name="title" select="title"/>
                    <xsl:variable name="membername" select="@user"/>
                    <tr>
                      <td><span class="octicon octicon-issue-opened"></span> <a href="{$githuburl}/{$orgname2}/{$reponame}/issues/{$issuekey}"><xsl:value-of select="$reponame"/>-<xsl:value-of select='@number'/></a></td>
                      <td>"<xsl:value-of select='substring(title,1,144)'/>"</td>
                      <td>
                       <xsl:for-each select='label'>
                        <xsl:variable name='labelColor' select='@color'/>
                        <span class='labelColor' style='background-color: #{$labelColor}'><xsl:value-of select='.'/></span>
                       </xsl:for-each>
                      </td>
                      <td><xsl:value-of select='@age'/>d</td>
                      <td><xsl:value-of select='substring(@created_at,1,10)'/></td>
                      <td><xsl:value-of select='substring(@updated_at,1,10)'/></td>
                      <td>
                      <xsl:if test="/github-dashdata/organization[@name=$orgname]/member[@login=$membername]">
                       <!-- TODO: How to allow users to pass in a url and member@internal to their internal directories? -->
                       <xsl:if test="$logo">
                        <span style="margin-right: 2px;"><sup><img src="{$logo}" width="8" height="8"/></sup></span>
                       </xsl:if>
                       <xsl:if test="not($logo)">
                        <span style="margin-right: 2px;"><sup>&#x2699;</sup></span>
                       </xsl:if>
                      </xsl:if>
                        <a href="{$githuburl}/{$membername}"><xsl:value-of select="@user"/></a>
                      </td>
                      <td><xsl:value-of select='@comments'/></td>
                      <td><xsl:value-of select='@prFileCount'/></td>
                      <td>+<xsl:value-of select='@prAdditions'/></td>
                      <td>-<xsl:value-of select='@prDeletions'/></td>
                    </tr>
                  </xsl:for-each>
                </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <xsl:if test="team">
            <div class="tab-pane" id="teams">
             <div class="data-grid-sortable tablesorter">
              <table id='teamTable' class='data-grid'>
                <thead>
                <tr><th>Team</th><th>Repos</th><th>Members</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="team">
                  <xsl:variable name="orgname2" select="@org"/>
                  <xsl:variable name="teamlink" select="@slug"/>
                  <tr><td><a href="team-{$teamlink}.html"><xsl:value-of select="@name"/> (<xsl:value-of select="@org"/>)</a><br/>
                    <xsl:value-of select="description"/>
                  </td>
                  <td>
                  <ul style='list-style-type: none;'>
                  <xsl:for-each select="repos/repo">
                    <xsl:variable name="reponame" select="."/>
                    <li><a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="."/></a></li>
                  </xsl:for-each>
                  </ul>
                  </td>
                  <td>
                  <ul style='list-style-type: none;'>
                  <xsl:for-each select="members/member">
                    <xsl:variable name="membername" select="."/>
                    <li>
                      <a href="{$githuburl}/{$membername}"><xsl:value-of select="."/></a></li>
                  </xsl:for-each>
                  </ul>
                  </td>
                  </tr>
                </xsl:for-each>
                </tbody>
              </table>
             </div>
            </div>
            </xsl:if>
            <xsl:if test="organization/member">
            <div class="tab-pane" id="members">
             <div class="data-grid-sortable tablesorter">
              <table id='memberTable' class='data-grid'>
                <thead>
                <tr><th>GitHub login</th><th>Name</th><th>Email</th><th>Company</th><th>Employee login</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="organization/member[not(@login=preceding::*/@login)]">
                  <xsl:variable name="memberlogin" select="@login"/>
                  <xsl:variable name="avatar" select="@avatar_url"/>
                  <tr><td><img width="35" height="35" src="{$avatar}&amp;s=35"/><a href="{$githuburl}/{$memberlogin}"><xsl:value-of select="@login"/></a></td>
                      <td><xsl:value-of select="name"/></td>
                      <td><xsl:value-of select="@email"/></td>
                      <td><xsl:value-of select="company"/></td>
                      <td>
                        <xsl:if test="not(@internal)"><span class="octicon octicon-question"></span></xsl:if>
                        <xsl:if test="@internal"><xsl:value-of select="@employee_email"/></xsl:if>
                      </td>
                  </tr>
                </xsl:for-each>
                </tbody>
              </table>
             </div>
            </div>
            </xsl:if>
            <!-- TODO: Merge with member above into people? -->
            <xsl:if test="repo/collaborators/collaborator">
            <div class="tab-pane" id="collaborators">
             <div class="data-grid-sortable tablesorter">
              <table id='collaboratorTable' class='data-grid'>
                <thead>
                <tr><th>Repository</th><th>Collaborators</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="repo">
                  <xsl:if test="collaborators/collaborator">
                  <tr><td>
                    <xsl:variable name="reponame" select="@name"/>
                    <xsl:variable name="orgname2" select="../@name"/>
                    <a href="{$githuburl}/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/></a>
                  </td>
                  <td><ul style='list-style-type: none;'>
                  <xsl:for-each select="collaborators/collaborator">
                    <xsl:variable name="collaborator" select="."/>
                    <li>
                      <xsl:if test="/github-dashdata/organization[@name=$orgname]/member[@login=$collaborator]">
                       <!-- TODO: How to allow users to pass in a url and member@internal to their internal directories? -->
                       <xsl:if test="$logo">
                        <span style="margin-right: 2px;"><sup><img src="{$logo}" width="8" height="8"/></sup></span>
                       </xsl:if>
                       <xsl:if test="not($logo)">
                        <span style="margin-right: 2px;"><sup>&#x2699;</sup></span>
                       </xsl:if>
                      </xsl:if>
                      <a href="{$githuburl}/{$collaborator}"><xsl:value-of select="."/></a>
                    </li>
                  </xsl:for-each></ul></td>
                  </tr>
                  </xsl:if>
                </xsl:for-each>
                </tbody>
              </table>
             </div>
            </div>
            </xsl:if>

            <!-- USER REPORTS -->
            <!-- TODO: This is one big copy of the above, need to refactor -->
            <xsl:for-each select="metadata/user-reports/report">
              <xsl:variable name="report" select="@key"/>
              <xsl:variable name="columntypes" select="column-type"/>
            <div class="tab-pane" id="{$report}">
             <h3>User Report: <xsl:value-of select="@name"/>
             (<xsl:value-of select="count(//reporting[@type=$report and not(text()=preceding::reporting[@type=$report]/text())])"/>)</h3> <!-- bug: unable to show summary count within a team mode -->
             <pre><xsl:value-of select="description"/></pre>
             <div class="data-grid-sortable tablesorter">
              <table id='{$report}Table' class='data-grid'>
               <thead><tr>
               <xsl:for-each select="column-type">
                <th><xsl:value-of select="."/></th>
               </xsl:for-each>
               </tr></thead>
               <tbody>
                  <xsl:for-each select="/github-dashdata/repo/reports/reporting[@type=$report and not(text()=preceding::reporting[@type=$report]/text())]">
                    <tr>
                     <xsl:if test="not(field)">
                      <xsl:call-template name="reporting-field">
                        <xsl:with-param name="orgname" select="../../@name"/>
                        <xsl:with-param name="logo" select="$logo"/>
                        <xsl:with-param name="columntypes" select="$columntypes"/>
                        <xsl:with-param name="value" select="."/>
                        <xsl:with-param name="index" select="1"/>
                        <xsl:with-param name="githuburl" select="$githuburl"/>
                      </xsl:call-template>
                     </xsl:if>
                     <xsl:if test="field">
                      <xsl:for-each select="field">
                       <xsl:call-template name="reporting-field">
                         <xsl:with-param name="orgname" select="../../@name"/>
                         <xsl:with-param name="logo" select="$logo"/>
                         <xsl:with-param name="columntypes" select="$columntypes"/>
                         <xsl:with-param name="value" select="."/>
                         <xsl:with-param name="index" select="position()"/>
                         <xsl:with-param name="githuburl" select="$githuburl"/>
                       </xsl:call-template>
                      </xsl:for-each>
                     </xsl:if>
                    </tr>
                  </xsl:for-each>
               </tbody>
              </table>
             </div>
            </div>
            </xsl:for-each>

            <!-- ISSUE REPORTS -->
            <xsl:for-each select="metadata/issue-reports/report">
              <xsl:variable name="report" select="@key"/>
              <xsl:variable name="columntypes" select="column-type"/>
            <div class="tab-pane" id="{$report}">
             <h3>User Report: <xsl:value-of select="@name"/>
             (<xsl:value-of select="count(//reporting[@type=$report and not(text()=preceding::reporting[@type=$report]/text())])"/>)</h3> <!-- bug: unable to show summary count within a team mode -->
             <pre><xsl:value-of select="description"/></pre>
             <div class="data-grid-sortable tablesorter">
              <table id='{$report}Table' class='data-grid'>
               <thead><tr>
               <xsl:for-each select="column-type">
                <th><xsl:value-of select="."/></th>
               </xsl:for-each>
               </tr></thead>
               <tbody>
                  <xsl:for-each select="/github-dashdata/repo/reports/reporting[@type=$report and not(text()=preceding::reporting[@type=$report]/text())]">
                    <tr>
                     <xsl:if test="not(field)">
                      <xsl:call-template name="reporting-field">
                        <xsl:with-param name="orgname" select="../../@name"/>
                        <xsl:with-param name="logo" select="$logo"/>
                        <xsl:with-param name="columntypes" select="$columntypes"/>
                        <xsl:with-param name="value" select="."/>
                        <xsl:with-param name="index" select="1"/>
                        <xsl:with-param name="githuburl" select="$githuburl"/>
                      </xsl:call-template>
                     </xsl:if>
                     <xsl:if test="field">
                      <xsl:for-each select="field">
                       <xsl:call-template name="reporting-field">
                         <xsl:with-param name="orgname" select="../../@name"/>
                         <xsl:with-param name="logo" select="$logo"/>
                         <xsl:with-param name="columntypes" select="$columntypes"/>
                         <xsl:with-param name="value" select="."/>
                         <xsl:with-param name="index" select="position()"/>
                         <xsl:with-param name="githuburl" select="$githuburl"/>
                       </xsl:call-template>
                      </xsl:for-each>
                     </xsl:if>
                    </tr>
                  </xsl:for-each>
               </tbody>
              </table>
             </div>
            </div>
            </xsl:for-each>

            <!-- REPO REPORTS -->
            <xsl:for-each select="metadata/repo-reports/report">
              <xsl:variable name="report" select="@key"/>
            <div class="tab-pane" id="{$report}">
             <h3>Repository Report: <xsl:value-of select="@name"/>
             (<xsl:value-of select="count(//reporting[@type=$report])"/>)</h3> <!-- bug: unable to show summary count within a team mode -->
             <pre><xsl:value-of select="description"/></pre>
             <div class="data-grid-sortable tablesorter">
              <table id='{$report}Table' class='data-grid'>
               <xsl:if test="not(column-type)">
                <thead>
                <tr><th>Issue Found In</th><th>Details</th></tr> 
                </thead>
                <tbody>
                <xsl:for-each select="/github-dashdata/repo/reports/reporting[@type=$report and not(@repo=preceding::reporting[@type=$report]/@repo)]">
                  <xsl:variable name="orgreponame" select="@repo"/>
                    <tr>
                      <td><a href="{$githuburl}/{$orgreponame}"><xsl:value-of select="@repo"/></a>
                        <xsl:if test="@private='true'">
                           <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                        </xsl:if>
                      </td>
                      <td><ul style='list-style-type: none;'>
                      <xsl:for-each select="/github-dashdata/repo/reports/reporting[@type=$report and @repo=$orgreponame]">
                        <xsl:variable name="file" select="file"/>
                        <xsl:variable name="lineno"><xsl:value-of select="file/@lineno"/></xsl:variable>
                        <xsl:variable name="linetxt">#L<xsl:value-of select="$lineno"/></xsl:variable>
                        <xsl:if test="file and file/@lineno">
                          <li><xsl:if test="message"><xsl:value-of select="message"/>: </xsl:if><a href="{$githuburl}/{$orgreponame}/tree/master/{$file}{$linetxt}"><xsl:value-of select="$file"/><xsl:value-of select="$linetxt"/></a><xsl:if test="string-length(match)>0"> - <xsl:value-of select="match"/></xsl:if></li>
                        </xsl:if>
                        <xsl:if test="file and not(file/@lineno)">
                          <li><xsl:if test="message"><xsl:value-of select="message"/>: </xsl:if><a href="{$githuburl}/{$orgreponame}/tree/master/{$file}"><xsl:value-of select="$file"/></a><xsl:if test="string-length(match)>0"> - <xsl:value-of select="match"/></xsl:if></li>
                        </xsl:if>
                        <xsl:if test="not(file) and file/@lineno">
                          <li>ERROR: Line number and no file. </li>
                        </xsl:if>
                        <xsl:if test="not(file) and not(file/@lineno)">
                          <li><xsl:value-of select="."/></li>
                        </xsl:if>
                      </xsl:for-each>
                      </ul></td>
                    </tr>
                </xsl:for-each>
                </tbody>
               </xsl:if>
               <xsl:if test="column-type">
               <xsl:variable name="columntypes" select="column-type"/>
               <!-- DUPLICATE OF ABOVE - TODO: MERGE -->
               <thead><tr>
               <xsl:for-each select="column-type">
                <th><xsl:value-of select="."/></th>
               </xsl:for-each>
               </tr></thead>
               <tbody>
                  <xsl:for-each select="/github-dashdata/repo/reports/reporting[@type=$report and not(text()=preceding::reporting[@type=$report]/text())]">
                    <tr>
                     <xsl:if test="not(field)">
                      <xsl:call-template name="reporting-field">
                        <xsl:with-param name="orgname" select="../../@name"/>
                        <xsl:with-param name="logo" select="$logo"/>
                        <xsl:with-param name="columntypes" select="$columntypes"/>
                        <xsl:with-param name="value" select="."/>
                        <xsl:with-param name="index" select="1"/>
                        <xsl:with-param name="githuburl" select="$githuburl"/>
                      </xsl:call-template>
                     </xsl:if>
                     <xsl:if test="field">
                      <xsl:for-each select="field">
                       <xsl:call-template name="reporting-field">
                         <xsl:with-param name="orgname" select="../../@name"/>
                         <xsl:with-param name="logo" select="$logo"/>
                         <xsl:with-param name="columntypes" select="$columntypes"/>
                         <xsl:with-param name="value" select="."/>
                         <xsl:with-param name="index" select="position()"/>
                         <xsl:with-param name="githuburl" select="$githuburl"/>
                       </xsl:call-template>
                      </xsl:for-each>
                     </xsl:if>
                    </tr>
                  </xsl:for-each>
               </tbody>
               </xsl:if>
              </table>
             </div>
            </div>
            </xsl:for-each>

          </div>
        </div>
          <div class="pull-right"><xsl:value-of select="metric/@start-time"/></div>

<script>
 plotChart("<xsl:value-of select='@dashboard'/>-repoCount", "LineChart")
 plotChart("<xsl:value-of select='@dashboard'/>-issueCount", "LineChart")
 plotChart("<xsl:value-of select='@dashboard'/>-issueTimeToClose", "BarChart")
 plotChart("<xsl:value-of select='@dashboard'/>-issueCommunityPie", "PieChart")
 plotChart("<xsl:value-of select='@dashboard'/>-pullRequestCount", "LineChart")
 plotChart("<xsl:value-of select='@dashboard'/>-prTimeToClose", "BarChart")
 plotChart("<xsl:value-of select='@dashboard'/>-prCommunityPie", "PieChart")
</script>

        <script type="text/javascript">
            $(function(){
                $("#repoTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#repoMetricsTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#issueMetricsTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#prMetricsTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#issueTable").tablesorter({
                    sortList: [[3,1]],
                });
                $("#prTable").tablesorter({
                    sortList: [[3,1]],
                });
                $("#memberTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#teamTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#repoTrafficTable").tablesorter({
                    sortList: [[0,0]],
                });
            <xsl:for-each select="metadata/user-reports/report">
                $("#<xsl:value-of select="@key"/>Table").tablesorter({
                    sortList: [[0,0]],
                });
            </xsl:for-each>
            <xsl:for-each select="metadata/issue-reports/report">
                $("#<xsl:value-of select="@key"/>Table").tablesorter({
                    sortList: [[0,0]],
                });
            </xsl:for-each>
            <xsl:for-each select="metadata/repo-reports/report">
                $("#<xsl:value-of select="@key"/>Table").tablesorter({
                    sortList: [[0,0]],
                });
            </xsl:for-each>
            });
        </script>

       <p>Generated by <a href="https://github.com/amzn/oss-dashboard">github.com/amzn/oss-dashboard</a>. </p>
       <xsl:if test="metadata/run-metrics/@usedRateLimit != 'n/a'">
         <p><xsl:value-of select="metadata/run-metrics/@usedRateLimit"/> GitHub requests made with <xsl:value-of select="metadata/run-metrics/@endRateLimit"/> remaining. </p>
       </xsl:if>
       <p>Report begun at <xsl:value-of select="substring(metadata/run-metrics/@refreshTime,1,10)"/>.<xsl:value-of select="substring(metadata/run-metrics/@refreshTime,12,5)"/>. </p>
       <p>Report written around <xsl:value-of select="substring(metadata/run-metrics/@generationTime,1,10)"/>.<xsl:value-of select="substring(metadata/run-metrics/@generationTime,12,5)"/>. </p>

      </body>
    </html>
  </xsl:template>

  <xsl:template name="reporting-field">
    <xsl:param name="orgname"/>
    <xsl:param name="logo"/>
    <xsl:param name="columntypes"/>
    <xsl:param name="value"/>
    <xsl:param name="index"/>
    <xsl:param name="githuburl"/>
    <xsl:if test="$columntypes[$index]/@type='text'">
     <td><xsl:value-of select="$value"/></td>
    </xsl:if>
    <xsl:if test="$columntypes[$index]/@type='date'">
     <td><xsl:value-of select="substring-before($value, 'T')"/></td>
    </xsl:if>
    <xsl:if test="$columntypes[$index]/@type='labels'">
      <xsl:if test="label">
       <td>
        <xsl:for-each select='label'>
          <xsl:variable name='labelColor' select='@color'/>
          <span class='labelColor' style='background-color: #{$labelColor}'><xsl:value-of select='.'/></span>
        </xsl:for-each>
       </td>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$columntypes[$index]/@type='url'">
      <xsl:if test="@id">
        <xsl:variable name="href" select="@id"/>
        <td><a href="{$href}"><xsl:value-of select="$value"/></a></td>
      </xsl:if>
      <xsl:if test="not(@id)">
        <td><a href="{$value}"><xsl:value-of select="$value"/></a></td>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$columntypes[$index]/@type='org/repo'">
     <xsl:variable name="reponame" select="substring-after($value, '/')"/>
     <xsl:variable name="repoorg" select="substring-before($value, '/')"/>
     <td><a href="{$githuburl}/{$value}"><xsl:value-of select="$value"/></a>
       <xsl:if test="/github-dashdata/organization[@name=$repoorg]/repo[@name=$reponame and @private='true']">
         <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
       </xsl:if>
       <xsl:if test="/github-dashdata/organization[@name=$repoorg]/repo[@name=$reponame and @fork='true']">
         <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
       </xsl:if>
     </td>
    </xsl:if>
    <xsl:if test="$columntypes[$index]/@type='org/team'">
     <xsl:variable name="teamname" select="substring-after($value, '/')"/>
     <xsl:variable name="teamorg" select="substring-before($value, '/')"/>
     <td><a href="{$githuburl}/orgs/{$teamorg}/teams/{$teamname}"><xsl:value-of select="$value"/></a></td>
    </xsl:if>
    <xsl:if test="$columntypes[$index]/@type='member'">
     <td>
      <xsl:if test="/github-dashdata/organization[@name=$orgname]/member[@login=$value]">
       <!-- TODO: How to allow users to pass in a url and member@internal to their internal directories? -->
       <xsl:if test="$logo">
        <span style="margin-right: 2px;"><sup><img src="{$logo}" width="8" height="8"/></sup></span>
       </xsl:if>
       <xsl:if test="not($logo)">
        <span style="margin-right: 2px;"><sup>&#x2699;</sup></span>
       </xsl:if>
      </xsl:if>
      <a href="{$githuburl}/{$value}"><xsl:value-of select="$value"/></a>
     </td>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

