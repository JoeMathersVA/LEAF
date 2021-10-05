<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    CDW controls
    Date Created: October 5, 2021
*/

$currDir = dirname(__FILE__);

include_once $currDir . '/../globals.php';

if (!class_exists('XSSHelpers'))
{
    require_once dirname(__FILE__) . '/../../libs/php-commons/XSSHelpers.php';
}
if (!class_exists('CommonConfig'))
{
    require_once dirname(__FILE__) . '/../../libs/php-commons/CommonConfig.php';
}

if(!class_exists('DataActionLogger'))
{
    require_once dirname(__FILE__) . '/../../libs/logger/dataActionLogger.php';
}

class CDW
{
    public $siteRoot = '';

    private $db;

    private $login;

    private $dataActionLogger;

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;

        // For Jira Ticket:LEAF-2471/remove-all-http-redirects-from-code
        //$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on' ? 'https' : 'http';
        $protocol = 'https';
        $this->siteRoot = "{$protocol}://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';

        $this->dataActionLogger = new \DataActionLogger($db, $login);
    }

    public function getVaccineStatus($empEmail = null) {
        if ($empEmail === null) {
            return 'Invalid Email.';
        }
    }

    public function modifyVaccine($empEmail = null) {
        if ($empEmail === null) {
            return 'Invalid Email.';
        }
    }

}
