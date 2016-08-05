# People

A database of persons included in Office of the Historian publications and datasets. The application provides a searchable list of all entries and an OpenRefine Reconciliation Service. 

## Data sources

- [The _Foreign Relations of the United States (FRUS)_ series](https://history.state.gov/historicaldocuments) (see raw data at the [HistoryAtState/frus](https://github.com/HistoryAtState/frus) GitHub repository)
- [_Visits to the United States by Foreign Leaders and Heads of State_](https://history.state.gov/departmenthistory/visits) (see raw data at the [HistoryAtState/visits](https://github.com/HistoryAtState/visits) GitHub repository)
- [_Principal Officers and Chiefs of Mission of the U.S. Department of State_](https://history.state.gov/departmenthistory/principals-chiefs) (see raw data at the [HistoryAtState/pocom](https://github.com/HistoryAtState/pocom) GitHub repository)
- Presidents of the United States

## Status

The data and app are in early beta. Caveat: Data identifiers are subject to change.

## Dependencies

- The data in the `data` collection is XML
- The application runs in [eXist-db](http://exist-db.org). Requires 3.0RC2.
- Building the installable package requires Apache Ant
- The OpenRefine Reconciliation Service targets OpenRefine 2.6 Beta

## Installation

- Check out the repository
- Run `ant`
- Upload build/people-0.1.xar to eXist-db's Dashboard > Package Manager
- Open http://localhost:8080/exist/apps/people
- The OpenRefine Reconciliation Service endpoint is at http://localhost:8080/exist/apps/people/reconcile

## URL structure

- Individual records are stored in `/people/id/{PERSON_IDENTIFIER}`, where `{PERSON_IDENTIFIER}` is a numerical ID.
- The default view is HTML. 
- The source XML data for a record can be viewed by appending `.xml` to the URL, i.e., `/people/id/{PERSON_IDENTIFIER}.xml`

## Data size and organization

The initial size of the dataset is ~16,000 person records. Each person record is assigned a numerical ID. In the mid-to-long term, data will approach and eventually exceed 100,000 records.

The numerical IDs assigned to person records begin with 100,001. (Starting with 100,001 instead of 1 helps with sorting in integer-ignorant environments, which treat 10 as coming before 2.)

For performance considerations in our environments (git, filesystem, and eXist-db database), we limit the number of files in a directory to 100. To facilitate this, we use a directory structure as follows:

Record 100001 is stored in: `100000/1/0/0/0`. This directory contains `100001.xml` through `100099.xml`. 

Record 113400 is stored in: `100000/1/1/3/4`. This directory contains `113400.xml` through `113499.xml`. 

