<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet method="html" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">

<!--
<github-dashdata dashboard='ORG'>
 <metadata>
  <navigation>
    <organization>org1</organization>
    <organization>org2</organization>
  </navigation>
  <reports>
    <report>DocsReporter</report>
    <report>CustomReporter</report>
  </reports>
  <db-reports>
    <db-report>DocsReporter</db-report>
    <db-report>CustomReporter</db-report>
  </db-reports>
 </metadata>
 <organization name='ORG'>
  <team name='NAME'>
    <description>XYZ</description>
    <repos>
        <repo>repo1</repo>
    </repos>
    <members>
      <member>member1</member>
    </members>
  </team>
  <repo name='repo1' private='false' fork='false' open_issue_count='0' has_wiki='false' language='Blah' stars='3' watchers='14' forks='0'>
    <description>ABC</description>
  </repo>
  <member internal='mem1' mail='mem1@example.com' disabled_2fa='true' name='member1'/>
  <github-review>
    <organization name=''>
      <repo name=''>
        <license>
        <reporting>
      </repo>
    </organization>
  </github-review>
 </organization>
</github-dashdata>

-->

  <xsl:template match="github-dashdata">
    <xsl:variable name="dashboardname" select="@dashboard"/>
    <xsl:variable name="orgname" select="organization/@name"/>
    <html>
      <head>
        <title>GitHub Dashboard: <xsl:value-of select='@dashboard'/><xsl:if test='@team'>/<xsl:value-of select='@team'/></xsl:if></title>
        <meta charset="utf-8"/>

        <!-- Lots of CDN usage here - you should replace this if you want to control the source of the JS/CSS -->
        <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/octicons/3.1.0/octicons.css" />
        <link type="text/css" rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" />
        <!-- xsl comment needed in JS to avoid an empty tag -->
        <script type="text/javascript" src="https://code.jquery.com/jquery-1.11.3.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/flot/0.8.3/jquery.flot.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/flot/0.8.3/jquery.flot.stack.min.js"><xsl:comment/></script>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.24.2/js/jquery.tablesorter.js"><xsl:comment/></script>

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
            .nav>li>a{display:block;}
            .nav>li>a:hover,.nav>li>a:focus{text-decoration:none;background-color:#aaaaaa;}
            .nav>li>a>img{max-width:none;}
            .nav>.pull-right{float:right;}
            .nav li+.nav-header{margin-top:9px;}
            .nav-list>li>a{margin-left:-15px;margin-right:-15px;text-shadow:0 1px 0 rgba(255, 255, 255, 0.5);}
            .nav-list>li>a{padding:3px 15px;}
            .nav-list>.active>a,.nav-list>.active>a:hover,.nav-list>.active>a:focus{color:#ffffff;text-shadow:0 -1px 0 rgba(0, 0, 0, 0.2);background-color:#0088cc;}
            .nav-tabs{*zoom:1;}
            .nav-tabs:before,.nav-tabs:after{display:table;content:"";line-height:0;}
            .nav-tabs:after{clear:both;}
            .nav-tabs>li{float:left;}
            .nav-tabs>li>a{padding-right:12px;padding-left:12px;margin-right:2px;line-height:14px;}
            .nav-tabs{border-bottom:1px solid #ddd;}
            .nav-tabs>li{margin-bottom:-1px;}
            .nav-tabs>li>a{padding-top:8px;padding-bottom:8px;line-height:17px;border:1px solid transparent;-webkit-border-radius:4px 4px 0 0;-moz-border-radius:4px 4px 0 0;border-radius:4px 4px 0 0;}
            .nav-tabs>li>a:hover,.nav-tabs>li>a:focus{border-color:#aaaaaa #aaaaaa #dddddd;}
            .nav-tabs>.active>a,.nav-tabs>.active>a:hover,.nav-tabs>.active>a:focus{color:#555555;background-color:#e8e8e8;border:1px solid #ddd;border-bottom-color:transparent;cursor:default;}

            .nav .dropdown-toggle .caret{border-top-color:#0088cc;border-bottom-color:#0088cc;margin-top:6px;}
            .nav .dropdown-toggle:hover .caret,.nav .dropdown-toggle:focus .caret{border-top-color:#ff5522;border-bottom-color:#ff5522;}
            .nav-tabs .dropdown-toggle .caret{margin-top:8px;}
        </style>

        <!-- This will fail - but if you drop a theme.css file in you can add your own Bootstrap Theme :) -->
        <link type="text/css" rel="stylesheet" href="bootstrap-theme.css" />
      </head>
      <body class="inverse">
        <ul class="nav nav-tabs pull-right" role="tablist">
          <xsl:if test="@team or @includes_private!='false'">
          <li class="dropdown">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
              Team <span class="caret"></span>
            </a>
            <ul class="dropdown-menu" role="menu">
              <xsl:for-each select='organization/team'>
                <xsl:variable name="teamlink" select="@escaped_name"/>
                <xsl:variable name="orgname2" select="../@name"/>
                <li><a href="{$orgname2}-team-{$teamlink}.html"><xsl:value-of select="../@name"/>::<xsl:value-of select="@name"/></a></li>
              </xsl:for-each>
            </ul>
          </li>
          </xsl:if>
          <li class="dropdown">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
              Organization <span class="caret"></span>
            </a>
            <ul class="dropdown-menu" role="menu">
              <xsl:for-each select="metadata/navigation/organization">
                <xsl:variable name="org" select="."/>
                <li><a href="{$org}.html"><xsl:value-of select="."/></a></li>
              </xsl:for-each>
            </ul>
          </li>
        </ul>

        <div class="well">
          <xsl:variable name="logo" select="@logo"/>
          <h2>GitHub Dashboard: <xsl:if test="@logo"><a href="https://github.com/{$orgname}"><img width="35" height="35" src="{$logo}&amp;s=35"/></a></xsl:if><xsl:value-of select='@dashboard'/><xsl:if test='@team'>/<xsl:value-of select='@team'/></xsl:if></h2>
          <ul id="tabs" class="nav nav-tabs">
            <li class="active"><a href="#overview" data-toggle="tab">Overview</a></li>
            <li><a href="#repositories" data-toggle="tab">Repositories (<xsl:value-of select="count(organization/repo)"/>)</a></li>
            <li><a href="#repometrics" data-toggle="tab">Repository Metrics (<xsl:value-of select="count(organization/repo)"/>)</a></li>
            <li><a href="#repocharts" data-toggle="tab">Repository Charts</a></li>
            <li><a href="#triage" data-toggle="tab">Triage (<xsl:value-of select="count(organization/repo/issues/issue)"/>)</a></li>
            <xsl:if test="not(organization/@team) and @includes_private!='false'">
            <li><a href="#teams" data-toggle="tab">Teams (<xsl:value-of select="count(organization/team)-1"/>)</a></li>
            </xsl:if>
            <li><a href="#members" data-toggle="tab">Members (<xsl:value-of select="count(organization/member)"/>)</a></li>
            <li class="dropdown"><a class="dropdown-toggle" data-toggle="dropdown" href="#">GitHub Reports <span class="caret"></span></a>
              <ul class="dropdown-menu" role="menu">
                <xsl:for-each select="metadata/db-reports/db-report">
                  <xsl:variable name="report" select="."/>
                  <li><a href="#{$report}" data-toggle="tab"><xsl:value-of select="."/>(<xsl:value-of select="count(/github-dashdata/organization/github-db-report/organization/db-reporting[@type=$report])"/>)</a></li> 
                </xsl:for-each>
              </ul>
            </li>
            <li class="dropdown"><a class="dropdown-toggle" data-toggle="dropdown" href="#">Source Reports <span class="caret"></span></a>
              <ul class="dropdown-menu" role="menu">
                <xsl:for-each select="metadata/reports/report">
                  <xsl:variable name="report" select="."/>
                  <li><a href="#{$report}" data-toggle="tab"><xsl:value-of select="."/>(<xsl:value-of select="count(/github-dashdata/organization/github-review/organization/repo/reporting[@type=$report])"/>)</a></li> 
                </xsl:for-each>
              </ul>
            </li>
          </ul>
          <div id="tabcontent" class="tab-content">

            <div class="tab-pane active" id="overview">

            <table cellpadding="10px" width="100%"><tr><td class="left">
             <h4>Issue/PR Count over Time</h4><br/>
             <div id="issueCountChart2" style="height:150px;width:400px;"><xsl:comment/></div><br/>
            </td><td class="right">
              <xsl:if test="organization/repo/release-data/release">
              <h4>Recent Releases</h4>
              <table class='data-grid'>
                <xsl:for-each select="organization/repo/release-data/release">
                  <xsl:sort select="@published_at" order="descending"/>
                  <xsl:variable name='release_url' select="@url"/>
                  <xsl:if test="position() &lt;= 5">
                    <tr><td><a href="{$release_url}"><xsl:value-of select='substring(@published_at,1,10)'/></a> - <xsl:value-of select='../../@name'/>: <xsl:value-of select='.'/></td></tr>
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
              <tr><th>Repo</th><th>Description</th><th>Teams</th>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="organization/repo">
              <xsl:variable name="reponame" select="@name"/>
              <xsl:variable name="orgname2" select="../@name"/>
              <xsl:variable name="homepage" select="@homepage"/>
                <tr><td>
                <a href="https://github.com/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/></a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>
                <td><xsl:value-of select="description"/><xsl:if test='@homepage!=""'> - <a href="{$homepage}"><xsl:value-of select="@homepage"/></a></xsl:if></td>
                  <td><ul style='list-style-type: none;'><xsl:for-each select='/github-dashdata/organization[@name=$orgname2]/team[repos/repo=$reponame]'>
                       <xsl:if test="@name != 'Owners' and @name != 'private read-only'">
                        <li><xsl:value-of select='@name'/></li>
                       </xsl:if>
                      </xsl:for-each></ul>
                  </td>
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
              <tr><th>Repo</th><th><a href="#" rel="tooltip" title="As Reported by GitHub/Licensee">Apparent License</a></th><th>Language</th>
                  <th>Created</th>
                  <th>Pushed</th>
                  <th>Updated</th>
                  <th><a href="#" rel="tooltip" title="Git Size in MB">Size</a></th>
                  <th><a href="#" rel="tooltip" title="# of Stars"><span class="octicon octicon-star"></span></a></th>
                  <th><a href="#" rel="tooltip" title="# of Watchers"><span class="octicon octicon-eye"></span></a></th>
                  <th><a href="#" rel="tooltip" title="# of Forks"><span class="octicon octicon-repo-forked"></span></a></th>
                  <th><a href="#" rel="tooltip" title="Issue Resolution %age"><span class="octicon octicon-issue-opened"></span></a></th>
                  <th><a href="#" rel="tooltip" title="Pull Request Resolution %age"><span class="octicon octicon-git-pull-request"></span></a></th>
              </tr>
              </thead>
              <tbody>
              <xsl:for-each select="organization/repo">
              <xsl:variable name="orgname2" select="../@name"/>
              <xsl:variable name="reponame" select="@name"/>
                <tr><td>
                <a href="https://github.com/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/></a>
                <xsl:if test="@private='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                </xsl:if>
                <xsl:if test="@fork='true'">
                   <sup><span style="margin-left: 5px" class="octicon octicon-repo-forked"></span></sup>
                </xsl:if>
                </td>
                <td><xsl:value-of select="/github-dashdata/organization/github-review/organization[@name=$orgname2]/repo[@name=$reponame]/license"/></td>
                <td><xsl:value-of select='@language'/></td>
                  <td><xsl:value-of select='substring(@created_at,1,10)'/></td>
                  <td><xsl:value-of select='substring(@pushed_at,1,10)'/></td>
                  <td><xsl:value-of select='substring(@updated_at,1,10)'/></td>
                  <td><xsl:value-of select="format-number(format-number(@size, '#.0') div 1024, '#.#')"/></td>
                  <td><xsl:value-of select='@stars'/></td>
                  <td><xsl:value-of select='@watchers'/></td>
                  <td><xsl:value-of select='@forks'/></td>
<!-- This combines issues and pull requests 
                  <td><xsl:value-of select='@open_issue_count'/></td>  
-->
                  <xsl:variable name="openIssue" select="count(issues/issue[@pull_request='false'])"/>
                  <xsl:if test='@closed_issue_count=0 and $openIssue=0'>
                    <td>&#8734;% (0 / 0)</td>
                  </xsl:if>
                  <xsl:if test='@closed_issue_count!=0 or $openIssue!=0'>
                    <td><xsl:value-of select='round(100 * @closed_issue_count div ($openIssue + @closed_issue_count))'/>% (<xsl:value-of select='@closed_issue_count'/> / <xsl:value-of select='$openIssue + @closed_issue_count'/>)</td>
                  </xsl:if>

                  <xsl:variable name="openPr" select="count(issues/issue[@pull_request='true'])"/>
                  <xsl:if test='@closed_pr_count=0 and $openPr=0'>
                    <td>&#8734;% (0 / 0)</td>
                  </xsl:if>
                  <xsl:if test='@closed_pr_count!=0 or $openPr!=0'>
                    <td><xsl:value-of select='round(100 * @closed_pr_count div ($openPr + @closed_pr_count))'/>% (<xsl:value-of select='@closed_pr_count'/> / <xsl:value-of select='$openPr + @closed_pr_count'/>)</td>
                  </xsl:if>
                </tr>
              </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <div class="tab-pane" id="repocharts">
              <!-- Need better layout here. The fixed size empty divs for the charts makes it harder to put them in a layout -->
             <table width="80%" align="center">
              <tr>
              <td class="left">
                <h4>Repo Count over Time</h4><br/>
                <div id="repoCountChart" style="height:150px;width:400px;"><xsl:comment/></div><br/>
              </td>
              <td class="right"><table class='data-grid'>
                <thead><tr><th>Year</th><th>Public</th><th>Private</th></tr></thead>
                <tbody>
                <tr><td>2009</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2009'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2009'>=substring(@created_at,1,4)])"/></td></tr>
                <tr><td>2010</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2010'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2010'>=substring(@created_at,1,4)])"/></td></tr>
                <tr><td>2011</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2011'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2011'>=substring(@created_at,1,4)])"/></td></tr>
                <tr><td>2012</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2012'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2012'>=substring(@created_at,1,4)])"/></td></tr>
                <tr><td>2013</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2013'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2013'>=substring(@created_at,1,4)])"/></td></tr>
                <tr><td>2014</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2014'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2014'>=substring(@created_at,1,4)])"/></td></tr>
                <tr><td>2015</td><td><xsl:value-of select="count(organization/repo[@private='false' and '2015'>=substring(@created_at,1,4)])"/></td><td><xsl:value-of select="count(organization/repo[@private='true' and '2015'>=substring(@created_at,1,4)])"/></td></tr>
                </tbody>
              </table></td>
              </tr>
              <tr><td colspan="2"><hr/></td></tr>
              <tr>
              <td class="left">
                <h4>Issue/PR Count over Time</h4><br/>
                <div id="issueCountChart" class="right" style="height:150px;width:400px;"><xsl:comment/></div><br/>
              </td>
              <td class="right"><table class='data-grid'>
                <thead><tr><th>Year</th><th align="center" colspan="2">Issues</th><th align="center" colspan="2">PRs</th></tr>
                       <tr><th></th><th>Still-Open</th><th>Closed</th><th>Still-Open</th><th>Closed</th></tr>
                </thead>
                <tbody>
                <tr><td>2009</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2009'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2009'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2009'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2009'>=@year]/@count)"/></td></tr>
                <tr><td>2010</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2010'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2010'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2010'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2010'>=@year]/@count)"/></td></tr>
                <tr><td>2011</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2011'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2011'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2011'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2011'>=@year]/@count)"/></td></tr>
                <tr><td>2012</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2012'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2012'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2012'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2012'>=@year]/@count)"/></td></tr>
                <tr><td>2013</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2013'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2013'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2013'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2013'>=@year]/@count)"/></td></tr>
                <tr><td>2014</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2014'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2014'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2014'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2014'>=@year]/@count)"/></td></tr>
                <tr><td>2015</td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2015'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2015'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2015'>=@year]/@count)"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2015'>=@year]/@count)"/></td></tr>
                </tbody>
              </table></td>
              </tr>
              <tr><td colspan="2"><hr/></td></tr>
              <tr>
              <td class="left">
                <h4>Time to Close an Issue</h4><br/>
                <div id="timeToCloseChart" style="height:150px;width:400px;"><xsl:comment/></div><br/>
              </td>
              <td class="right"><table class='data-grid'>
                <thead><tr><th>Range</th><th>Issues</th><th>PRs</th></tr></thead>
                <tbody>
                <tr><td>1 hour</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 hour'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 hour'])"/></td></tr>
                <tr><td>3 hours</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='3 hours'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='3 hours'])"/></td></tr>
                <tr><td>9 hours</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='9 hours'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='9 hours'])"/></td></tr>
                <tr><td>1 day</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 day'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 day'])"/></td></tr>
                <tr><td>1 week</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 week'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 week'])"/></td></tr>
                <tr><td>1 month</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 month'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 month'])"/></td></tr>
                <tr><td>1 quarter</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 quarter'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 quarter'])"/></td></tr>
                <tr><td>1 year</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 year'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 year'])"/></td></tr>
                <tr><td>over 1 year</td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='over 1 year'])"/></td><td><xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='over 1 year'])"/></td></tr>
                </tbody>
              </table></td>
              </tr>
              <tr><td colspan="2"><hr/></td></tr>
             </table>
            </div>
            <div class="tab-pane" id="triage">
             <div class="data-grid-sortable tablesorter">
              <table id='triageTable' class='data-grid'>
                <thead>
                <tr><th>Issue</th><th>Title</th><th>Created</th><th>Age</th><th>Updated</th><th>Requester</th><th>Comments</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="organization/repo">
                  <xsl:variable name="orgname2" select="../@name"/>
                  <xsl:variable name="reponame" select="@name"/>
                  <xsl:for-each select="issues/issue">
                    <xsl:variable name="issuekey" select="@number"/>
                    <xsl:variable name="title" select="."/>
                    <xsl:variable name="membername" select="@user"/>
                    <tr>
                    <!-- https://github.com/aws/aws-cli/pull/1260 -->
                    <xsl:if test='@pull_request="true"'>
                      <td><span class="octicon octicon-git-pull-request"></span> <a href="https://github.com/{$orgname2}/{$reponame}/pull/{$issuekey}"><xsl:value-of select="$reponame"/>-<xsl:value-of select='@number'/></a></td>
                    </xsl:if>
                    <!-- https://github.com/aws/aws-cli/issues/1256 -->
                    <xsl:if test='@pull_request="false"'>
                      <td><span class="octicon octicon-issue-opened"></span> <a href="https://github.com/{$orgname2}/{$reponame}/issues/{$issuekey}"><xsl:value-of select="$reponame"/>-<xsl:value-of select='@number'/></a></td>
                    </xsl:if>
                      <td>"<xsl:value-of select='substring(.,1,144)'/>"</td>
                      <td><xsl:value-of select='substring(@created_at,1,10)'/></td>
                      <td><xsl:value-of select='@age'/>d</td>
                      <td><xsl:value-of select='substring(@updated_at,1,10)'/></td>
                      <td>
                      <a href="https://github.com/{$membername}"><xsl:value-of select="@user"/></a>
                      </td>
                      <td><xsl:value-of select='@comments'/></td>
                    </tr>
                  </xsl:for-each>
                </xsl:for-each>
              </tbody>
              </table>
             </div>
            </div>
            <xsl:if test="not(@team) and @includes_private!='false'">
            <div class="tab-pane" id="teams">
              <table id='teamTable' class='data-grid'>
                <thead>
                <tr><th>Team</th><th>Repos</th><th>Members</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="organization/team">
                 <xsl:if test="@name != 'Owners'">
                  <xsl:variable name="orgname2" select="../@name"/>
                  <xsl:variable name="teamname" select="@name"/>
                  <tr><td><a href="https://github.com/orgs/{$orgname2}/teams/{$teamname}"><xsl:value-of select="@name"/></a><br/>
                    <xsl:value-of select="description"/>
                  </td>
                  <td>
                  <ul style='list-style-type: none;'>
                  <xsl:for-each select="repos/repo">
                    <xsl:variable name="reponame" select="."/>
                    <li><a href="https://github.com/{$orgname2}/{$reponame}"><xsl:value-of select="."/></a></li>
                  </xsl:for-each>
                  </ul>
                  </td>
                  <td>
                  <ul style='list-style-type: none;'>
                  <xsl:for-each select="members/member">
                    <xsl:variable name="membername" select="."/>
                    <li>
                      <a href="https://github.com/{$membername}"><xsl:value-of select="."/></a></li>
                  </xsl:for-each>
                  </ul>
                  </td>
                  </tr>
                 </xsl:if>
                </xsl:for-each>
                </tbody>
              </table>
            </div>
            </xsl:if>
            <div class="tab-pane" id="members">
             <div class="data-grid-sortable tablesorter">
              <table id='memberTable' class='data-grid'>
                <thead>
                <tr><th>GitHub login</th><th>Employee login</th><th>2FA?</th></tr>
                </thead>
                <tbody>
                <xsl:for-each select="organization/member">
                  <xsl:variable name="membername" select="@name"/>
                  <tr><td><a href="https://github.com/{$membername}"><xsl:value-of select="@name"/></a></td>
                      <td>
                        <xsl:if test="not(@internal)"><span class="octicon octicon-question"></span></xsl:if>
                        <xsl:if test="@internal"><xsl:value-of select="@employee_email"/></xsl:if>
                      </td>
                      <td><xsl:if test="@disabled_2fa='false'">
                        <span style="display:none">1</span><span class="octicon octicon-check"></span>
                      </xsl:if>
                      <xsl:if test="@disabled_2fa='true'">
                        <span style="display:none">0</span>
                      </xsl:if></td>
                  </tr>
                </xsl:for-each>
                </tbody>
              </table>
             </div>
            </div>

            <!-- DB REPORTS -->
            <xsl:for-each select="metadata/db-reports/db-report">
              <xsl:variable name="report" select="."/>
            <div class="tab-pane" id="{$report}">
             <div class="data-grid-sortable tablesorter">
              <table id='{$report}Table' class='data-grid'>
                <thead>
<!-- TODO: Pull this from the metadata after it starts showing there -->
                <tr><th>First Column (<xsl:value-of select="count(/github-dashdata/organization/github-db-report/organization/db-reporting[@type=$report])"/>)</th></tr> <!-- bug: unable to show summary count within a team mode -->
                </thead>
                <tbody>
                <xsl:for-each select="/github-dashdata/organization">
                  <xsl:variable name="orgname2" select="@name"/>
                  <xsl:for-each select="/github-dashdata/organization/github-db-report/organization[@name=$orgname2]/db-reporting[@type=$report]">
                      <tr>
                        <td><xsl:value-of select="."/></td>
                      </tr>
                  </xsl:for-each>
                </xsl:for-each>
                </tbody>
              </table>
             </div>
            </div>
            </xsl:for-each>

            <!-- SOURCE REPORTS -->
            <xsl:for-each select="metadata/reports/report">
              <xsl:variable name="report" select="."/>
            <div class="tab-pane" id="{$report}">
             <div class="data-grid-sortable tablesorter">
              <table id='{$report}Table' class='data-grid'>
                <thead>
                <tr><th>Issue Found In (<xsl:value-of select="count(/github-dashdata/organization/github-review/organization/repo/reporting[@type=$report])"/>)</th><th>Details</th></tr> <!-- bug: unable to show summary count within a team mode -->
                </thead>
                <tbody>
                <xsl:for-each select="/github-dashdata/organization/repo">
                  <xsl:variable name="orgname2" select="../@name"/>
                  <xsl:variable name="reponame" select="@name"/>
                  <xsl:if test="/github-dashdata/organization/github-review/organization[@name=$orgname2]/repo[@name=$reponame]/reporting[@type=$report]">
                    <tr>
                      <td><a href="https://github.com/{$orgname2}/{$reponame}"><xsl:value-of select="@name"/></a>
                        <xsl:if test="@private='true'">
                           <sup><span style="margin-left: 5px" class="octicon octicon-lock"></span></sup>
                        </xsl:if>
                      </td>
                      <td><ul style='list-style-type: none;'>
                      <xsl:for-each select="/github-dashdata/organization/github-review/organization[@name=$orgname2]/repo[@name=$reponame]/reporting[@type=$report]">
                        <xsl:variable name="file" select="@file"/>
                        <xsl:variable name="lineno">#L<xsl:value-of select="@lineno"/></xsl:variable>
                        <xsl:if test="@file and @lineno">
                          <li><a href="https://github.com/{$orgname2}/{$reponame}/tree/master/{$file}{$lineno}"><xsl:value-of select="@file"/>#L<xsl:value-of select="@lineno"/></a><xsl:if test="string-length(.)>0"> - <xsl:value-of select="."/></xsl:if></li>
                        </xsl:if>
                        <xsl:if test="@file and not(@lineno)">
                          <li><a href="https://github.com/{$orgname2}/{$reponame}/tree/master/{$file}"><xsl:value-of select="@file"/></a><xsl:if test="string-length(.)>0"> - <xsl:value-of select="."/></xsl:if></li>
                        </xsl:if>
                        <xsl:if test="not(@file) and @lineno">
                          <li>ERROR: Line number an no file. </li>
                        </xsl:if>
                        <xsl:if test="not(@file) and not(@lineno)">
                          <li><xsl:value-of select="."/></li>
                        </xsl:if>
                      </xsl:for-each>
                      </ul></td>
                    </tr>
                  </xsl:if>
                </xsl:for-each>
                </tbody>
              </table>
             </div>
            </div>
            </xsl:for-each>

          </div>
        </div>
          <div class="pull-right"><xsl:value-of select="metric/@start-time"/></div>

<!-- The years are hardcoded :( -->
<script>
publicRepoCount=[
  [2009, <xsl:value-of select="count(organization/repo[@private='false' and '2009'>=substring(@created_at,1,4)])"/>],
  [2010, <xsl:value-of select="count(organization/repo[@private='false' and '2010'>=substring(@created_at,1,4)])"/>],
  [2011, <xsl:value-of select="count(organization/repo[@private='false' and '2011'>=substring(@created_at,1,4)])"/>],
  [2012, <xsl:value-of select="count(organization/repo[@private='false' and '2012'>=substring(@created_at,1,4)])"/>],
  [2013, <xsl:value-of select="count(organization/repo[@private='false' and '2013'>=substring(@created_at,1,4)])"/>],
  [2014, <xsl:value-of select="count(organization/repo[@private='false' and '2014'>=substring(@created_at,1,4)])"/>],
  [2015, <xsl:value-of select="count(organization/repo[@private='false' and '2015'>=substring(@created_at,1,4)])"/>],
]

privateRepoCount=[
  [2009, <xsl:value-of select="count(organization/repo[@private='true' and '2009'>=substring(@created_at,1,4)])"/>],
  [2010, <xsl:value-of select="count(organization/repo[@private='true' and '2010'>=substring(@created_at,1,4)])"/>],
  [2011, <xsl:value-of select="count(organization/repo[@private='true' and '2011'>=substring(@created_at,1,4)])"/>],
  [2012, <xsl:value-of select="count(organization/repo[@private='true' and '2012'>=substring(@created_at,1,4)])"/>],
  [2013, <xsl:value-of select="count(organization/repo[@private='true' and '2013'>=substring(@created_at,1,4)])"/>],
  [2014, <xsl:value-of select="count(organization/repo[@private='true' and '2014'>=substring(@created_at,1,4)])"/>],
  [2015, <xsl:value-of select="count(organization/repo[@private='true' and '2015'>=substring(@created_at,1,4)])"/>],
]

$.plot($("#repoCountChart"), [ { data: privateRepoCount, label: 'private'}, { data: publicRepoCount, label: 'public' } ],

{
    series: {
        stack: true,
        lines: {
            show: true,
            lineWidth: 2,
        },
        points: { show: true },
        shadowSize: 2
    },
    grid: {
        borderWidth: 0
    },
    legend: {
        position: 'nw'
    },
    colors: ["#FA5833", "#2FABE9"]
});
</script>

<script>
issuesOpened=[
  ['2009', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2009'>=@year]/@count)"/>],
  ['2010', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2010'>=@year]/@count)"/>],
  ['2011', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2011'>=@year]/@count)"/>],
  ['2012', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2012'>=@year]/@count)"/>],
  ['2013', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2013'>=@year]/@count)"/>],
  ['2014', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2014'>=@year]/@count)"/>],
  ['2015', <xsl:value-of select="sum(organization/repo/issue-data/issues-opened['2015'>=@year]/@count)"/>],
]

issuesClosed=[
  ['2009', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2009'>=@year]/@count)"/>],
  ['2010', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2010'>=@year]/@count)"/>],
  ['2011', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2011'>=@year]/@count)"/>],
  ['2012', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2012'>=@year]/@count)"/>],
  ['2013', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2013'>=@year]/@count)"/>],
  ['2014', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2014'>=@year]/@count)"/>],
  ['2015', <xsl:value-of select="sum(organization/repo/issue-data/issues-closed['2015'>=@year]/@count)"/>],
]

prsOpened=[
  ['2009', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2009'>=@year]/@count)"/>],
  ['2010', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2010'>=@year]/@count)"/>],
  ['2011', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2011'>=@year]/@count)"/>],
  ['2012', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2012'>=@year]/@count)"/>],
  ['2013', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2013'>=@year]/@count)"/>],
  ['2014', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2014'>=@year]/@count)"/>],
  ['2015', <xsl:value-of select="sum(organization/repo/issue-data/prs-opened['2015'>=@year]/@count)"/>],
]

prsClosed=[
  ['2009', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2009'>=@year]/@count)"/>],
  ['2010', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2010'>=@year]/@count)"/>],
  ['2011', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2011'>=@year]/@count)"/>],
  ['2012', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2012'>=@year]/@count)"/>],
  ['2013', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2013'>=@year]/@count)"/>],
  ['2014', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2014'>=@year]/@count)"/>],
  ['2015', <xsl:value-of select="sum(organization/repo/issue-data/prs-closed['2015'>=@year]/@count)"/>],
]

$.plot($("#issueCountChart"), [ 
{ data: prsClosed, label: 'closed-prs' }, 
{ data: issuesClosed, label: 'closed-issues'}, 
{ data: prsOpened, label: 'opened-prs'},
{ data: issuesOpened, label: 'opened-issues'}, 
],

{
    series: {
        stack: true,
        lines: {
            show: true,
            fill: true,
            lineWidth: 2,
        },
        points: { show: true },
        shadowSize: 2
    },
    grid: {
        borderWidth: 0
    },
    legend: {
        position: 'nw'
    },
    colors: ["#BA3823", "#FA5833", "#0F8BC9", "#2FABE9"]
});
$.plot($("#issueCountChart2"), [ 
{ data: prsClosed, label: 'closed-prs' }, 
{ data: issuesClosed, label: 'closed-issues'}, 
{ data: prsOpened, label: 'opened-prs'},
{ data: issuesOpened, label: 'opened-issues'}, 
],

{
    series: {
        stack: true,
        lines: {
            show: true,
            fill: true,
            lineWidth: 2,
        },
        points: { show: true },
        shadowSize: 2
    },
    grid: {
        borderWidth: 0
    },
    legend: {
        position: 'nw'
    },
    colors: ["#BA3823", "#FA5833", "#0F8BC9", "#2FABE9"]
});
</script>

<script>
issueResolveTimes=[
  [1, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 hour'])"/>],
  [2, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='3 hours'])"/>],
  [3, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='9 hours'])"/>],
  [4, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 day'])"/>],
  [5, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 week'])"/>],
  [6, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 month'])"/>],
  [7, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 quarter'])"/>],
  [8, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='1 year'])"/>],
  [9, <xsl:value-of select="sum(organization/repo/issue-data/age-count/issue-count[@age='over 1 year'])"/>],
]

prResolveTimes=[
  [1, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 hour'])"/>],
  [2, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='3 hours'])"/>],
  [3, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='9 hours'])"/>],
  [4, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 day'])"/>],
  [5, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 week'])"/>],
  [6, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 month'])"/>],
  [7, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 quarter'])"/>],
  [8, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='1 year'])"/>],
  [9, <xsl:value-of select="sum(organization/repo/issue-data/age-count/pr-count[@age='over 1 year'])"/>],
]
$.plot($("#timeToCloseChart"), [ { data: issueResolveTimes, label: 'Issues'}, { data: prResolveTimes, label: 'Pull Requests' } ],

{
    series: {
        stack: true,
        bars: { show: true, barWidth: 0.6 },
    },
    xaxis: {
        ticks: [
          [1, '1 hour'],
          [2, '3 hours'],
          [3, '9 hours'],
          [4, '1 day'],
          [5, '1 week'],
          [6, '1 month'],
          [7, '1 quarter'],
          [8, '1 year'],
          [9, 'over 1 year'] 
        ]
    },
    grid: {
        borderWidth: 0
    },
    legend: {
        position: 'ne'
    },
    colors: ["#FA5833", "#2FABE9"]
});
</script>

        <script type="text/javascript">
            $(function(){
                $("#repoTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#repoMetricsTable").tablesorter({
                    sortList: [[0,0]],
                });
                $("#triageTable").tablesorter({
                    sortList: [[2,1]],
                });
                $("#memberTable").tablesorter({
                    sortList: [[0,0]],
                });
            <xsl:for-each select="metadata/reports/report">
                $("#<xsl:value-of select="."/>Table").tablesorter({
                    sortList: [[0,0]],
                });
            </xsl:for-each>
            <xsl:for-each select="metadata/db-reports/db-report">
                $("#<xsl:value-of select="."/>Table").tablesorter({
                    sortList: [[0,0]],
                });
            </xsl:for-each>
            });
        </script>

      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>

