<p:declare-step version='1.0' name="main"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:p="http://www.w3.org/ns/xproc">
<p:input port="source"/>
<p:output port="result">
  <p:pipe step="sch" port="report"/>
</p:output>

<p:validate-with-schematron assert-valid="false" name="sch">
  <p:input port="schema">
    <p:document href="../schema/docbook.sch"/>
  </p:input>
  <p:input port="parameters"><p:empty/></p:input>
</p:validate-with-schematron>

<p:sink/>

</p:declare-step>
