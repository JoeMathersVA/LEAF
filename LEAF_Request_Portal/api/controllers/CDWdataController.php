<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

require '../sources/CDW.php';

if (!class_exists('XSSHelpers'))
{
    include_once dirname(__FILE__) . '/../../../libs/php-commons/XSSHelpers.php';
}

class CDWdataController extends RESTfulResponse
{
    public $index = array();

    private $API_VERSION = 1;    // Integer

    private $cdw;

    private $db;

    //private $CDW_db;

    private $login;

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;
        $this->cdw = new CDW($db, $login);
    }

    public function get($act)
    {
        $db = $this->db;
        $login = $this->login;
        $cdw = $this->cdw;

        $this->index['GET'] = new ControllerMap();
        $cm = $this->index['GET'];
        $this->index['GET']->register('cdw/version', function () {
            return $this->API_VERSION;
        });

        $this->index['GET']->register('cdw/vaccine/status', function () use ($cdw) {
            return $cdw->getVaccineStatus();
        });

        return $this->index['GET']->runControl($act['key'], $act['args']);
    }

    public function post($act)
    {
        $db = $this->db;
        $login = $this->login;
        $cdw = $this->cdw;

        $this->verifyAdminReferrer();

        $this->index['POST'] = new ControllerMap();
        $this->index['POST']->register('cdw', function ($args) {
        });

        $this->index['POST']->register('cdw/vaccine/submit', function ($args) use ($db, $login, $cdw) {
            return $cdw->modifyVaccine();
        });

        return $this->index['POST']->runControl($act['key'], $act['args']);
    }

    public function delete($act)
    {
        $db = $this->db;
        $login = $this->login;
        $cdw = $this->cdw;

        $this->verifyAdminReferrer();

        $this->index['DELETE'] = new ControllerMap();
        $this->index['DELETE']->register('cdw', function ($args) {
        });

        return $this->index['DELETE']->runControl($act['key'], $act['args']);
    }
}
