const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const { Client } = require('pg');

const queries = [];

Client.prototype.connect = function connect() {};
Client.prototype.query = function query(sql, values, callback) {
    queries.push({ sql, values });
    callback(null, { rows: [] });
};

const employees = require('../routes/employees');

function response() {
    return {
        redirectLocation: null,
        redirect(location) {
            this.redirectLocation = location;
        }
    };
}

after(() => {
    delete Client.prototype.connect;
    delete Client.prototype.query;
});

test('adds a user and redirects to the employee list', () => {
    queries.length = 0;
    const res = response();

    employees.save({
        body: {
            name: 'Ada Lovelace',
            job: 'Engineer',
            department: 'Technology',
            salary: '90000',
            hire_date: '2026-09-26'
        }
    }, res);

    assert.match(queries[0].sql, /^INSERT INTO employee/);
    assert.deepEqual(queries[0].values, [
        'Ada Lovelace', 'Engineer', 'Technology', '90000', '2026-09-26'
    ]);
    assert.equal(res.redirectLocation, '/employees');
});

test('edits a user and redirects to the employee list', () => {
    queries.length = 0;
    const res = response();

    employees.update({
        params: { id: '7' },
        body: {
            name: 'Ada Byron',
            job: 'Lead Engineer',
            department: 'Research',
            salary: '110000',
            hire_date: '2026-09-26'
        }
    }, res);

    assert.match(queries[0].sql, /^UPDATE employee SET/);
    assert.deepEqual(queries[0].values, [
        'Ada Byron', 'Lead Engineer', 'Research', '110000', '2026-09-26', '7'
    ]);
    assert.equal(res.redirectLocation, '/employees');
});

test('deletes a user and redirects to the employee list', () => {
    queries.length = 0;
    const res = response();

    employees.delete({ params: { id: '7' } }, res);

    assert.match(queries[0].sql, /^DELETE FROM employee/);
    assert.deepEqual(queries[0].values, ['7']);
    assert.equal(res.redirectLocation, '/employees');
});