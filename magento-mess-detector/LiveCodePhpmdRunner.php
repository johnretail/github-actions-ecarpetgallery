<?php

/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */

/**
 * PHP Code Mess v1.3.3 tool wrapper
 */

namespace Magento\TestFramework\CodingStandard\Tool;

use \Magento\TestFramework\CodingStandard\ToolInterface;

class LiveCodePhpmdRunner implements ToolInterface
{
    /**
     * Ruleset directory
     *
     * @var string
     */
    private $rulesetFile;

    /**
     * Report file
     *
     * @var string
     */
    private $reportFile;

    /**
     * Constructor
     *
     * @param string $rulesetDir \Directory that locates the inspection rules
     * @param string $reportFile Destination file to write inspection report to
     */
    public function __construct($rulesetFile, $reportFile)
    {
        $this->reportFile = $reportFile;
        $this->rulesetFile = $rulesetFile;
    }

    /**
     * Whether the tool can be ran on the current environment
     *
     * @return bool
     */
    public function canRun()
    {
        return class_exists(\PHPMD\TextUI\Command::class);
    }

    /**
     * {@inheritdoc}
     */
    public function run(array $whiteList)
    {
        $commandLineArguments = [
            'run_file_mock', //emulate script name in console arguments
            $this->getSourceCodePath($whiteList),
	    'ansi', //report format
            $this->rulesetFile,
            '--reportfile',
            $this->reportFile,
            '--suffixes',
            'php',
            '--exclude',
            'vendor/,tmp/,var/,generated/,.git/,.idea/'
	];

        $options = new \PHPMD\TextUI\CommandLineOptions($commandLineArguments);

        // PHPMD 2.10+ requires an OutputInterface in constructor
        // Check constructor signature to support both old and new PHPMD versions
        $reflection = new \ReflectionClass(\PHPMD\TextUI\Command::class);
        $constructor = $reflection->getConstructor();
        
        if ($constructor && $constructor->getNumberOfRequiredParameters() > 0) {
            // Newer PHPMD version - need to provide OutputInterface
            // Create a simple output that writes to the report file
            $output = new class($this->reportFile) implements \Symfony\Component\Console\Output\OutputInterface {
                private $reportFile;
                public function __construct($reportFile) { $this->reportFile = $reportFile; }
                public function write($messages, $newline = false, $options = 0) {}
                public function writeln($messages, $options = 0) {}
                public function setVerbosity($verbosity) {}
                public function getVerbosity(): int { return self::VERBOSITY_NORMAL; }
                public function isQuiet() { return false; }
                public function isVerbose() { return false; }
                public function isVeryVerbose() { return false; }
                public function isDebug() { return false; }
                public function setDecorated($decorated) {}
                public function isDecorated() { return false; }
            };
            $command = new \PHPMD\TextUI\Command($output);
        } else {
            // Older PHPMD version - no constructor parameters
            $command = new \PHPMD\TextUI\Command();
        }

        return $command->run($options, new \PHPMD\RuleSetFactory());
    }
    private function getSourceCodePath($whiteList)
    {
        if (!empty($whiteList)) {
            $whiteList = array_map(function($gitHubWorkspace){
                             return $_SERVER['GITHUB_WORKSPACE'] . '/' . $gitHubWorkspace;
	    }, $whiteList);
            return implode(',', $whiteList);
        }
	return $_SERVER['GITHUB_WORKSPACE'] ?: '/app/code/RetaiLogists';
    }
}
