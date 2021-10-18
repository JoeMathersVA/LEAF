<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

require '../sources/CDW.php';

if (!class_exists('XSSHelpers'))
{
    include_once dirname(__FILE__) . '/../../../libs/php-commons/XSSHelpers.php';
}

/**
 * Purpose: Class to connect to VA's CDW databases (MSSQL)
 */
class CDWdataController extends RESTfulResponse
{
    public $index = array();

    private $API_VERSION = 1;    // Integer

    private $cdw;

    private $db;

    private $login;

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;
        $this->cdw = new CDW($db, $login);
    }

    public function verifyVaccineReferrer() {
        return ($this->verifyAdminReferrer() && strpos($_SERVER['REQUEST_URI'], 'NATIONAL/101/vaccine_data_reporting') !== 'false');
    }

    public function get($act)
    {
        //$this->verifyVaccineReferrer();
        $db = $this->db;
        $login = $this->login;
        $cdw = $this->cdw;

        $this->index['GET'] = new ControllerMap();
        $cm = $this->index['GET'];
        $cm->register('cdw/version', function () {
            return $this->API_VERSION;
        });

        /** Validate Vaccine Status in CDW - Expects Valid Email Address and Optional Pathway*/
        $cm->register('cdw/vaccine/status', function () use ($cdw) {
            return $cdw->getVaccineStatus();
        });

        return $cm->runControl($act['key'], $act['args']);
    }

    public function post($act)
    {
        $cdw = $this->cdw;

        $this->index['POST'] = new ControllerMap();
        $cm = $this->index['POST'];
        $cm->register('cdw', function ($args) {
        });

        /** Modify Vaccine when record ID unknown **/
        $cm->register('cdw/vaccine/[digit]/submit', function ($args) use ($cdw) {
            return $cdw->modifyVaccine((int)$args[0]);
        });

        return $this->index['POST']->runControl($act['key'], $act['args']);
    }

    public function delete($act)
    {
        $cdw = $this->cdw;

        //$this->verifyVaccineReferrer();

        $this->index['DELETE'] = new ControllerMap();
        $this->index['DELETE']->register('cdw', function ($args) {
        });

        // Expected digit is LEAF Record ID to be removed from CDW Uploads
        $this->index['DELETE']->register('cdw/vaccine/[digit]/remove', function ($args) use ($cdw) {
            return $cdw->deleteVaccine((int)$args[0]);
        });

        return $this->index['DELETE']->runControl($act['key'], $act['args']);
    }
}
