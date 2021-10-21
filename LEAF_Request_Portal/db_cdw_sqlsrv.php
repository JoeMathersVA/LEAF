<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    db_cdw_sqlsrv is a convenience layer
    Date Created: October 1, 2021
 */

class DB_CDW
{
    private $db;                        // The database object

    private $dbHost;
    private $dbName;

    private $connectionInfo;

    private $log = array('<span style="color: red">Debug Log is ON</span>');    // error log for debugging

    private $debug = false;             // Are we debugging?

    private $time = 0;

    private $dryRun = false;            // only applies to prepared queries

    private $limit = '';

    private $isConnected = false;

    // Connect to the database
    public function __construct($database)
    {
        $this->dbHost = getenv('CDW_HOST', true);
        $this->dbName = $database;

        $this->isConnected = true;
        try
        {
            $this->db = new PDO("sqlsrv:Server={$this->dbHost};Database={$this->dbName}");
        }
        catch (PDOException $e)
        {
            echo '<!-- Database Error: ' . $e->getMessage() . ' -->';
            $this->isConnected = false;
        }
    }

    public function __destruct()
    {
        $this->db = null;
    }

    // Log errors from the database
    public function logError($error)
    {
        $this->log[] = $error;
    }

    public function beginTransaction()
    {
        if ($this->debug)
        {
            $this->log[] = 'Beginning Transaction';
        }

        return $this->db->beginTransaction();
    }

    public function commitTransaction()
    {
        if ($this->debug)
        {
            $this->log[] = 'Committing Transaction';
        }

        return $this->db->commit();
    }

    /**
     * Limits number of results.
     * The limit is cleared before each query, and must be reset if needed
     * @param int $offset
     * @param int $quantity
     */
    public function limit($offset, $quantity = 0)
    {
        $offset = (int)$offset;
        $quantity = (int)$quantity;

        if ($quantity > 0)
        {
            $this->limit = "LIMIT {$offset},{$quantity}";
        }
    }

    // Raw Queries the database and returns an associative array
    public function query($sql)
    {
        if ($this->limit != '')
        {
            $sql = "{$sql} {$this->limit}";
            $this->limit = '';
        }

        $time1 = microtime(true);
        if ($this->debug)
        {
            $this->log[] = $sql;
            if ($this->debug >= 2)
            {
                $query = $this->db->query('EXPLAIN ' . $sql);
                $this->log[] = $query->fetchAll(PDO::FETCH_ASSOC);
            }
        }

        $res = $this->db->query($sql);
        if ($res !== false)
        {
            return $res->fetchAll(PDO::FETCH_ASSOC);
        }
        $err = $this->db->errorInfo();
        $this->logError($err[2]);

        if ($this->debug)
        {
            $this->time += microtime(true) - $time1;
            print $this->db->errorCode();
            echo "\n";
            print_r ($this->db->errorInfo());
        }
    }

    public function prepared_query($sql, $vars, $dry_run = false)
    {
        if ($this->limit != '')
        {
            $sql = "{$sql} {$this->limit}";
            $this->limit = '';
        }

        $query = null;

        $time1 = microtime(true);
        if ($this->debug)
        {
            $q['sql'] = $sql;
            $q['vars'] = $vars;
            $this->log[] = $q;
            if ($this->debug >= 2)
            {
                $query = $this->db->prepare('EXPLAIN ' . $sql);
                $query->execute($vars);
                $this->log[] = $query->fetchAll(PDO::FETCH_ASSOC);
            }
        }

        if ($dry_run == false && $this->dryRun == false)
        {
            $query = $this->db->prepare($sql);
            $query->execute($vars);
        }
        else
        {
            $this->log[] = 'Dry run: query not executed';
        }

        if ($this->debug)
        {
            $this->time += microtime(true) - $time1;
            print $this->db->errorCode();
            echo "\n";
            print_r ($this->db->errorInfo());
        }

        return $query->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Query a key-value table structure
     * Returns an associative array
     * @param string $sql
     * @param string $key - Name of the column in the table
     * @param mixed $value - Name of the column in the table as a string, or list of columns in an array
     * @param array $vars - parameratized variables
     */
    public function query_kv($sql, $key, $value, $vars = array())
    {
        $out = array();
        $res = $this->prepared_query($sql, $vars);

        if (!is_array($value))
        {
            foreach ($res as $result)
            {
                $out[$result[$key]] = $result[$value];
            }
        }
        else
        {
            foreach ($res as $result)
            {
                foreach ($value as $column)
                {
                    $out[$result[$key]][$column] = $result[$column];
                }
            }
        }

        return $out;
    }

    // Translates the * wildcard to SQL % wildcard
    public function parseWildcard($query)
    {
        return str_replace('*', '%', $query . '*');
    }

    // Clean up all wildcards
    public function cleanWildcards($input)
    {
        $input = str_replace('%', '*', $input);
        $input = str_replace('?', '*', $input);
        $input = preg_replace('/\*+/i', '*', $input);
        $input = preg_replace('/(\s)+/i', ' ', $input);
        $input = preg_replace('/(\*\s\*)+/i', '', $input);

        return $input;
    }

    public function getLastInsertID()
    {
        return $this->db->lastInsertId();
    }

    public function isConnected()
    {
        return $this->isConnected;
    }

    public function disableDebug()
    {
        $this->debug = false;
    }

    public function enableDebug()
    {
        $this->debug = 1;
    }

    public function disableDryRun()
    {
        $this->dryRun = false;
    }

    public function enableDryRun()
    {
        $this->dryRun = true;
    }
}
