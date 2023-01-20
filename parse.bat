@ECHO OFF
SET TEST_CURRENT_DIR=%CLASSPATH:.;=%
if "%TEST_CURRENT_DIR%" == "%CLASSPATH%" ( SET CLASSPATH=.;%CLASSPATH% )
@ECHO ON

cd Parser
java org.antlr.v4.gui.TestRig Pragma page ..\%1.prag 
cd ..

